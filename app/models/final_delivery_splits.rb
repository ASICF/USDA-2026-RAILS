class FinalDeliverySplits

    def self.preprocessing input_directory='P:\Vol_1\Bernard_Test', packing_slip=PackingSlip.find(144), current_user = User.first

        response = {
            status: false,
            message: nil
        }

        unmatched_tiles = []
        verified_splits = []

        # get the packing slip project and state
        project = packing_slip.project
        state = packing_slip.state
        psn = packing_slip.name

        # convert the path to unix pathing
        unix_path = Task.build input_directory
        split_folder = "#{unix_path}/Big_Tiles"
        psn_folder_name = packing_slip.name.gsub(/[^\w\s_-]+/, '').gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2').gsub(/\s+/, '_')
        final_delivery_folder = "#{unix_path}/Final_Delivery_#{psn_folder_name}"

        p "------------"
        p unix_path
        p split_folder
        p final_delivery_folder
        p "------------"

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                if !File.directory?(final_delivery_folder)
                    raise Exception, "Could not find Final Delivery Folder \"Final_Delivery_#{psn_folder_name}\" in \"#{input_directory}\""
                end

                # Check the user supplied path
                # => Make sure it's all scoped under the project folder
                # => Check if the Big Tiles folder exists

                if !File.directory?(split_folder)

                    # => Create the Big Tiles folder if it doesn't exist
                    FileUtils.mkdir_p(split_folder)

                    raise Exception, "No splits found in #{split_folder}"
                end

                # iterate the tiffs in the folder
                Dir.glob("#{split_folder}/*.tif").each do |file|
                    # p file

                    filename = File.basename(file)
                    filename_without_extension = File.basename(file, '.tif')

                    # extract the poly id
                    parsed_poly_id = FinalDeliverySplits.extract_id filename_without_extension, project

                    # p "-------"
                    # p parsed_poly_id
                    
                    # find the tile based on the state, project, parsed poly id and packing slip
                    tile = state.tiles.find_by(poly_id: parsed_poly_id[:poly_id], project: project, packing_slip: packing_slip)

                    if tile.present?

                        # p "#{final_delivery_folder}/#{project}/#{tile.state_abv}/#{tile.county.full_fips}/Orthos/#{tile.filename}.tif"

                        # check if the tile is in the final delivery folder
                        if File.file?("#{final_delivery_folder}/#{project}/#{tile.state_abv}/#{tile.county.full_fips}/Orthos/#{tile.filename}.tif")

                            # check the tif bands to make sure they are valid
                            gdalinfo_response = `gdalinfo "#{split_folder}/#{filename_without_extension}.tif"`

                            if gdalinfo_response.include? "Band 4"
                                verified_splits << "#{split_folder}/#{filename_without_extension}"
                            else
                                # output[:errors] << "#{filename} Does Not have 4th Band"
                                raise Exception, "#{filename} Does Not have 4th Band"
                            end

                            # check if the tiff is projected
                            listgeo_response = `listgeo '#{split_folder}/#{filename}'`

                            raise Exception, "#{filename} does Not have GTCitationGeoKey. Check if the Tiff is projected." if !listgeo_response.include? "GTCitationGeoKey"
                            raise Exception, "#{filename} does Not have PCSCitationGeoKey. Check if the Tiff is projected." if !listgeo_response.include? "PCSCitationGeoKey"
                        else
                            # filename does not exist within the county foulder
                            raise Exception, "#{filename} Does not exist within #{final_delivery_folder}/#{project}/#{tile.state_abv}/#{tile.county.full_fips}/Orthos"
                        end

                    else
                        # check if the tile exists in the app
                        tile = Tile.find_by(poly_id: parsed_poly_id[:poly_id])
        
                        if !tile.present? 

                            # Add to the unmatched tiles that the filename was not found in the app
                            # => Send email after validation process notifying user
                            unmatched_tiles << filename
                        end
                    end

                end

                p " "
                p "Verified Splits"
                p "--------------"
                pp verified_splits

                p " "
                p "Unmatched Tiles"
                p "--------------"
                p unmatched_tiles

                if unmatched_tiles.length > 0
                    # Send email notifying user there are unmatched tiles in the split folder
                end

                if verified_splits.count > 0
                    response = {
                        status: true,
                        message: "Found #{verified_splits.count} splits, Split tool process has started as a queued job that can be tracked in the Job Tracker. You will receive an email once it finishes."
                    }
                else
                    response = {
                        status: false,
                        message: "No splits found that match within #{psn}. Process was not initialized."
                    }
                end
                
            rescue Exception => exception
                Rails.logger.error "#{project} Final Delivery Prep Error: #{exception.message}"
                p "-----------"
                p exception.backtrace.count
                exception.backtrace.each do |x|
                    next if !x.include? "final_delivery_splits.rb"
                    x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
                p [$1,$2,$4]
                end
                p "-----------"

                response[:status] = false
                response[:message] = [exception.message]

                raise ActiveRecord::Rollback
            end
        end

        # If the verified splits is not empty and there are no unmatched 
        if verified_splits.length > 0
            p "ALL GOOD DUDE"
            # FinalDelivery.delay.nrisl_execute params, current_user, path
            FinalDeliverySplits.processing verified_splits, packing_slip, split_folder, final_delivery_folder, current_user, input_directory, project
        end

        # return to client
        return response

    end

    def self.processing verified_splits, packing_slip, split_folder, final_delivery_folder, current_user, input_directory, project

        p "------------"
        p "Processing"
        p packing_slip
        p "split_folder: #{split_folder}"
        p "final_delivery_folder: #{final_delivery_folder}"
        pp verified_splits
        p "------------"

        process_success = false
        error_message = "Something went wrong. Contact Programming."
        split_folder_path = nil

        # track where files are moved so they don't need to be parsed out again
        original_arr = []
        delete_arr = []
        move_arr = []
        migration_arr = []

        # Created new Job
        job = Job.create(
            started_at: Time.now,
            message: "Processing Request...",
            active: true,
            process_type: "#{project} Final Delivery Splits",
            creator: current_user
        )

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Create a new History record
                history = History.new
                history.action_type = "Final Delivery Splits"
                history.creator = current_user
                history.save

                # Create the folder structure 
                # => OriginalSplit
                # => ToDelete
                # => ToMove

                # check if the packing slip folder already exists within the splits folder

                # Get the folder friendly file name
                psn_folder_name = packing_slip.name.gsub(/[^\w\s_-]+/, '').gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2').gsub(/\s+/, '_')

                split_folder_path = FinalDeliverySplits.build_split_folder "#{split_folder}/#{psn_folder_name}", nil

                # Create subfolders
                to_delete_path = "#{split_folder_path}/toDelete"
                original_path = "#{split_folder_path}/originalSplit"
                to_move_path = "#{split_folder_path}/toMove"

                # create the toDelete folder inside the updated folder path
                FileUtils.mkdir_p(to_delete_path) unless File.directory?(to_delete_path)

                # create the original folder inside the updated folder path
                FileUtils.mkdir_p(original_path) unless File.directory?(original_path)

                # create the toMove folder inside the updated folder path
                FileUtils.mkdir_p(to_move_path) unless File.directory?(to_move_path)

                matched = []

                Dir.glob("#{split_folder}/*.tif").each do |file|
            
                    next if file.include? "toDelete"

                    path = File.dirname(file)
                    # filename = File.basename(file)
                    filename_without_extension = File.basename(file, '.tif')

                    # get the poly id
                    parsed_poly_id = FinalDeliverySplits.extract_id filename_without_extension, packing_slip.project

                    p "-------"
                    p parsed_poly_id

                    # Find the tile in the packing slip
                    tile = packing_slip.tiles.ortho_processed.dumped.shipped.find_by(poly_id: parsed_poly_id[:poly_id])

                    if tile.nil?
                        # raise Exception, "#{filename}: Could not find associated tile poly_id using: #{arr[3]}"
                        # errors << {file: file, message: "Could not find associated tile poly_id using: #{arr[3]}"}
                        next
                    end

                    # Get the county full fips
                    county_fips = tile.county.full_fips

                    # find all the files that match the tile filename
                    delivery_files = Dir.glob("#{final_delivery_folder}/**/#{tile.filename}.*")

                    # check if any of the tiffs in the final delivery folder match
                    if delivery_files.size == 0

                        # Check if the file exists in the toDelete folder
                        if Dir.glob("#{to_delete_path}/#{county_fips}/#{tile.filename}.*").count == 0
                            raise Exception, "#{tile.filename}: Could not find file in #{to_delete_path} or within to delete path"
                        end

                    end

                    delivery_path = nil

                    if delivery_files.size > 0

                        delivery_path = File.dirname(delivery_files.first)
                        # delivery_filename = File.basename(delivery_file.first)
                        # delivery_filename_without_extension = File.basename(delivery_file.first, '.tif')

                        FileUtils.mkdir_p("#{to_delete_path}/#{county_fips}") unless File.directory?("#{to_delete_path}/#{county_fips}")
                        FileUtils.mkdir_p("#{original_path}/#{county_fips}") unless File.directory?("#{original_path}/#{county_fips}")
                        FileUtils.mkdir_p("#{to_move_path}/#{county_fips}") unless File.directory?("#{to_move_path}/#{county_fips}")

                        # check if the file exists in the delivery path and if so then delete the 

                        ## TIF ##
                        # Check if the file exists in the final delivery folder and in the toDelete folder (means the script failed and re-running)
                        if File.file?("#{delivery_path}/#{tile.filename}.tif") && File.file?("#{to_delete_path}/#{county_fips}/#{tile.filename}.tif")
                            # If so then delete the toDelete file so it can be re-copied
                            File.delete("#{to_delete_path}/#{county_fips}/#{tile.filename}.tif")
                            p "- tif Found in the ToDelete folder, deleting and moving from Final Delivery Path"
                        end

                        # If the File exists in the Final delivery folder and not in the To Delete folder then copy
                        if File.file?("#{delivery_path}/#{tile.filename}.tif") && !File.file?("#{to_delete_path}/#{county_fips}/#{tile.filename}.tif")
                            # Delete the file form the 
                            FileUtils.mv("#{delivery_path}/#{tile.filename}.tif", "#{to_delete_path}/#{county_fips}/")
                            delete_arr << {filename: tile.filename, from: "#{delivery_path}/", to: "#{to_delete_path}/#{county_fips}/"}
                        end

                        ## TFW ##
                        # Check if the file exists in the final delivery folder and in the toDelete folder (means the script failed and re-running)
                        if File.file?("#{delivery_path}/#{tile.filename}.tfw") && File.file?("#{to_delete_path}/#{county_fips}/#{tile.filename}.tfw")
                            # If so then delete the toDelete file so it can be re-copied
                            File.delete("#{to_delete_path}/#{county_fips}/#{tile.filename}.tfw")
                            p "- tfw Found in the ToDelete folder, deleting and moving from Final Delivery Path"
                        end

                        # If the File exists in the Final delivery folder and not in the To Delete folder then copy
                        if File.file?("#{delivery_path}/#{tile.filename}.tfw") && !File.file?("#{to_delete_path}/#{county_fips}/#{tile.filename}.tfw")
                            # Delete the file form thetile.filename
                            FileUtils.mv("#{delivery_path}/#{tile.filename}.tfw", "#{to_delete_path}/#{county_fips}/")
                        end

                        ## XML ##
                        # Check if the file exists in the final delivery folder and in the toDelete folder (means the script failed and re-running)
                        if File.file?("#{delivery_path}/#{tile.filename}.xml") && File.file?("#{to_delete_path}/#{county_fips}/#{tile.filename}.xml")
                            # If so then delete the toDelete file so it can be re-copied
                            File.delete("#{to_delete_path}/#{county_fips}/#{tile.filename}.xml")
                            p "- xml Found in the ToDelete folder, deleting and moving from Final Delivery Path"
                        end

                        # If the File exists in the Final delivery folder and not in the To Delete folder then copy
                        if File.file?("#{delivery_path}/#{tile.filename}.xml") && !File.file?("#{to_delete_path}/#{county_fips}/#{tile.filename}.xml")
                            # Delete the file form the 
                            FileUtils.mv("#{delivery_path}/#{tile.filename}.xml", "#{to_delete_path}/#{county_fips}/")
                        end
                    end

                    # Check if the metadata file exists in the toDelete folder

                    if Dir.glob("#{to_delete_path}/#{county_fips}/#{tile.filename}.xml").size != 1
                        raise Exception, "#{tile.filename}: Could not find file in #{final_delivery_folder}"
                    end

                    # copy the metadata into the original folder
                    # read the metadata file and vlaidate it
                    # open and update the metadata with the poly ids

                    # copy the metadata file to the folder and rename it
                    FileUtils.cp("#{to_delete_path}/#{county_fips}/#{tile.filename}.xml", "#{original_path}/#{county_fips}/#{filename_without_extension}.xml")

                    # Read the template file
                    metadata_text = File.read("#{original_path}/#{county_fips}/#{filename_without_extension}.xml")

                    # check if the metadata file is valid
                    if metadata_text.scan(">#{parsed_poly_id[:poly_id]}<").count == 0
                        raise Exception, "#{"#{original_path}/#{county_fips}/#{filename_without_extension}.xml"}: Could not find matching poly_id #{parsed_poly_id[:poly_id]} in copied metadata"
                    end

                    # Update the variables
                    metadata_text = metadata_text.gsub(parsed_poly_id[:poly_id], parsed_poly_id[:split_poly_id])

                    # Write the text to the county folder as a new text file
                    File.open("#{original_path}/#{county_fips}/#{filename_without_extension}.xml", "w") {|file| file.puts metadata_text }

                    # cut and paste the file to a new folder
                    FileUtils.mv("#{path}/#{filename_without_extension}.tif", "#{original_path}/#{county_fips}/")
                    FileUtils.mv("#{path}/#{filename_without_extension}.tfw", "#{original_path}/#{county_fips}/")

                    original_arr << {filename: filename_without_extension, from: path, to: "#{original_path}/#{county_fips}/"}

                    # Generate and update GTF File
                    # Use geotifcp to create the tiff with updated headers to the toMove folder

                    # Set the GeoTIF tags
                    # 1. Create the GTF file for the tf
                    gtf_file = "#{original_path}/#{county_fips}/#{filename_without_extension}.gtf"

                    # 2. Output the listgeo command to a GTF File
                    listgeo_response = system("listgeo '#{original_path}/#{county_fips}/#{filename_without_extension}.tif' > '#{gtf_file}'")

                    # update the gtf file
                    FinalDelivery.build_gtf gtf_file, filename_without_extension, tile.utm.zone, parsed_poly_id[:split_poly_id]

                    # Update the Tiff tags and copy to the county folder
                    geotif_response = system("geotifcp -8 -g '#{gtf_file}' '#{original_path}/#{county_fips}/#{filename_without_extension}.tif' '#{to_move_path}/#{county_fips}/#{filename_without_extension}.tif'")

                    FileUtils.cp("#{original_path}/#{county_fips}/#{filename_without_extension}.tfw", "#{to_move_path}/#{county_fips}/#{filename_without_extension}.tfw")
                    FileUtils.cp("#{original_path}/#{county_fips}/#{filename_without_extension}.xml", "#{to_move_path}/#{county_fips}/#{filename_without_extension}.xml")

                    move_arr << {filename: filename_without_extension, from: "#{original_path}/#{county_fips}/", to: "#{to_move_path}/#{county_fips}/"}

                    # iterate the delete arr and extract the final delivery county folder name
                    match_delete = delete_arr.find {|delArr| delArr[:filename] === tile.filename}

                    migration_arr << {
                        filename: filename_without_extension,
                        from: "#{to_move_path}/#{county_fips}",
                        to: match_delete[:from]
                    }

                end

                p "----------"
                p "original_arr"
                pp original_arr
                p "delete_arr"
                pp delete_arr
                p "move_arr"
                pp move_arr
                p "migration_arr"
                pp migration_arr
                p "----------"

                # start the migration process
                FinalDeliverySplits.migration final_delivery_folder, project, migration_arr

                # validation
                FinalDelivery.validate_deliverable input_directory, packing_slip, project, current_user

                p "Back in Processing"

                message = "Moved #{migration_arr.count} to Final Delivery folder at #{input_directory}"

                history.update(message: message)

                # Update the job
                job.update(
                    finished_at: Time.now,
                    success: true,
                    active: false,
                    message: message
                )

                process_success = true

            rescue Exception => exception
                Rails.logger.error "Final Delivery Error: #{exception.message}"
                error_message = exception.message
                p "-----------"
                p exception.backtrace.count
                exception.backtrace.each do |x|
                    next if !x.include? "final_delivery.rb"
                    x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
                p [$1,$2,$4]
                end
                p "-----------"

                # Delete the history object if present
                history.destroy if history.present?

                # Update the process 
                process_success = false

                # Rollback the transacction to wipe and and all database changes
                raise ActiveRecord::Rollback
            end
        end

        # Check if the job is still running which means it failed
        if !process_success
            job.update(
                finished_at: Time.now,
                active: false,
                success: false,
                message: "#{project} Final Delivery Splits Failed",
                error_message: error_message
            )

            # Cleanup the files
            if split_folder_path
                FinalDeliverySplits.cleanup split_folder_path, original_arr, delete_arr, migration_arr
            end
        end

        p "done"

        # Iterate the Big Tiles folder Tiffs and extract the poliyid to check against the database
        # => IMPORTANT! Production should add the _1, _2 to the end of the file instead of after the PolyID for better parsing 
        # => Check against the database to find the Packing Slip info
        # => check if associated tiff is in the ToDelete folder then the final delivery folder
        # => If match then copy the .tif and .tfw to the OriginalSplit folder
        # => Move the associated .tiff, .tfw, and .xml files from the Final Delivery to the ToDelete folder
        # ==> Track the folder paths in a text file so that it can be referenced when moving files back by the app or manually. 

        # Copy the XML from the ToDelete Folder into the ToMove folder
        # Update the filename of the xml to match the split filename
        # => Update the contents of the file with the new PolyID

        # Update the TiffTags to reference the new PolyID

        # once complete run the Migration
        # => Keep this separate from the migration process in case it fails it will be easier to move them back and forth
    end

    def self.migration final_delivery_folder, project, migration_arr=[]

        # migration_arr = [{:filename=>"ortho_AL_15_7341010700H6BB000c_1_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019",
        #     :to=>"/vol1/Bernard_Test/Final_Delivery_20240906_AL/SL/AL/01019/Orthos/"},
        #     {:filename=>"ortho_AL_15_7341010700H6BB000c_2_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019",
        #     :to=>"/vol1/Bernard_Test/Final_Delivery_20240906_AL/SL/AL/01019/Orthos/"},
        #     {:filename=>"ortho_AL_15_7341010700H6BB000c_3_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019",
        #     :to=>"/vol1/Bernard_Test/Final_Delivery_20240906_AL/SL/AL/01019/Orthos/"},
        #     {:filename=>"ortho_AL_15_7341010700H6BB000c_4_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019",
        #     :to=>"/vol1/Bernard_Test/Final_Delivery_20240906_AL/SL/AL/01019/Orthos/"},
        #     {:filename=>"ortho_AL_15_7341010700H6BB000c_5_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019",
        #     :to=>"/vol1/Bernard_Test/Final_Delivery_20240906_AL/SL/AL/01019/Orthos/"},
        #     {:filename=>"ortho_AL_15_7341010700H6BB000c_6_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019",
        #     :to=>"/vol1/Bernard_Test/Final_Delivery_20240906_AL/SL/AL/01019/Orthos/"},
        #     {:filename=>"ortho_AL_15_7341010700H6BB000c_7_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019",
        #     :to=>"/vol1/Bernard_Test/Final_Delivery_20240906_AL/SL/AL/01019/Orthos/"},
        #     {:filename=>"ortho_AL_15_7341010700H6BB000c_8_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019",
        #     :to=>"/vol1/Bernard_Test/Final_Delivery_20240906_AL/SL/AL/01019/Orthos/"},
        #     {:filename=>"ortho_AL_15_7341010700H6BB000c_9_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019",
        #     :to=>"/vol1/Bernard_Test/Final_Delivery_20240906_AL/SL/AL/01019/Orthos/"},
        #     {:filename=>"ortho_AL_15_7341010700H6BB000c_10_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019",
        #     :to=>"/vol1/Bernard_Test/Final_Delivery_20240906_AL/SL/AL/01019/Orthos/"}]

        # Iterate the county Folders in the ToMove folder into the County folder of the Final Delivery

        p "Migration"
        p "-------------------"
        pp migration_arr
        p "-------------------"

        migration_arr.each do |obj|

            p "Copying #{obj[:filename]}"
            p " - tif"
            FileUtils.cp("#{obj[:from]}/#{obj[:filename]}.tif", "#{obj[:to]}/#{obj[:filename]}.tif")
            p " - tfw"
            FileUtils.cp("#{obj[:from]}/#{obj[:filename]}.tfw", "#{obj[:to]}/#{obj[:filename]}.tfw")
            p " - xml"
            FileUtils.cp("#{obj[:from]}/#{obj[:filename]}.xml", "#{obj[:to]}/#{obj[:filename]}.xml")
        end

        # build the Tile Index once completed
        self.build_tile_index final_delivery_folder, project
    end

    def self.validation
        # Pass to the Final Delivery Validation
    end

    def self.cleanup split_final_delivery_folder, original_arr=[], delete_arr=[], migration_arr=[]
        # Runs if the script fails
        # => Copy the original tile from the ToDelete to it's county folder in the Final Delivery
        # => Copy the split tiles from OriginalSplit into the Big Tiles folder

        # verified_splits = [
        #     "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_10_20240820",
        #     "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_9_20240820",
        #     "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_8_20240820",
        #     "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_7_20240820",
        #     "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_6_20240820",
        #     "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_5_20240820",
        #     "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_4_20240820",
        #     "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_3_20240820",
        #     "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_2_20240820",
        #     "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_1_20240820"
        # ]

        # original_arr = [{:filename=>"ortho_AL_15_7341010700H6BB000c_1_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_2_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_3_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_4_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_5_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_6_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_7_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_8_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_9_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_10_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/"}]
        
        # delete_arr = [{:filename=>"ortho_AL_15_7341010700H6BB000c_20240820",
        #     :from=>"/vol1/Bernard_Test/Final_Delivery_20240906_AL/SL/AL/01019/Orthos/",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toDelete/01019/"}]
        
        # move_arr = [{:filename=>"ortho_AL_15_7341010700H6BB000c_1_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_2_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_3_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_4_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_5_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_6_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_7_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_8_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_9_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019/"},
        #    {:filename=>"ortho_AL_15_7341010700H6BB000c_10_20240820",
        #     :from=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/originalSplit/01019/",
        #     :to=>"/vol1/Bernard_Test/Big_Tiles/20240906_AL_12/toMove/01019/"}]

        # split_final_delivery_folder = "/vol1/Bernard_Test/Big_Tiles/20240906_AL_12"

        # iterate the move arr and move the files back to the split folder
        p "Original Split Move"
        p "-----------------------------"
        original_arr.each do |obj|
            pp obj

            # check if the file exists in the to path
            if !File.directory?(obj[:from])
                raise Exception, "Directory \"#{obj[:from]}\" does not exist! Could not move files back to previous folders"
            end

            # check and move the tiff
            if File.file?("#{obj[:to]}/#{obj[:filename]}.tif")
                p " - Moving tiff"
                FileUtils.mv("#{obj[:to]}/#{obj[:filename]}.tif", obj[:from])
            end

            # check and move the tfw
            if File.file?("#{obj[:to]}/#{obj[:filename]}.tfw")
                p " - Moving tfw"
                FileUtils.mv("#{obj[:to]}/#{obj[:filename]}.tfw", obj[:from])
            end
        end

        # iterate the delete arr and move the files back to the county final delivery folder
        p "Delete Move"
        p "-----------------------------"
        delete_arr.each do |obj|
            pp obj

            # check if the file exists in the to path
            if !File.directory?(obj[:from])
                raise Exception, "Directory \"#{obj[:from]}\" does not exist! Could not move files back to previous folders"
            end

            # check and move the tiff
            if File.file?("#{obj[:to]}/#{obj[:filename]}.tif")
                p " - Moving tiff"
                FileUtils.mv("#{obj[:to]}/#{obj[:filename]}.tif", obj[:from])
            end

            # check and move the tfw
            if File.file?("#{obj[:to]}/#{obj[:filename]}.tfw")
                p " - Moving tfw"
                FileUtils.mv("#{obj[:to]}/#{obj[:filename]}.tfw", obj[:from])
            end

            # check and move the tfw
            if File.file?("#{obj[:to]}/#{obj[:filename]}.xml")
                p " - Moving xml"
                FileUtils.mv("#{obj[:to]}/#{obj[:filename]}.xml", obj[:from])
            end
        end

        # iterate the delete arr and move the files back to the county final delivery folder
        p "Migration Move"
        p "-----------------------------"
        migration_arr.each do |obj|
            pp obj

            # check if the file exists in the to path
            if !File.directory?(obj[:from])
                raise Exception, "Directory \"#{obj[:from]}\" does not exist! Could not move files back to previous folders"
            end

            # check and move the tiff
            if File.file?("#{obj[:to]}/#{obj[:filename]}.tif")
                p " - Moving tiff"
                FileUtils.mv("#{obj[:to]}/#{obj[:filename]}.tif", obj[:from])
            end

            # check and move the tfw
            if File.file?("#{obj[:to]}/#{obj[:filename]}.tfw")
                p " - Moving tfw"
                FileUtils.mv("#{obj[:to]}/#{obj[:filename]}.tfw", obj[:from])
            end

            # check and move the tfw
            if File.file?("#{obj[:to]}/#{obj[:filename]}.xml")
                p " - Moving xml"
                FileUtils.mv("#{obj[:to]}/#{obj[:filename]}.xml", obj[:from])
            end
        end

    end

    private

    def self.extract_id filename="ortho_AL_15_7341010700H6BB000c_20240820", project="SL"
        # takes a filename of a split and return the polyid

        result = {
            poly_id: nil,
            split_poly_id: nil,
        }

        arr = filename.split("_")

        if project === "SL"
            # the first three indices should be "Ortho", state abv, and "15" so skip those
            modified_arr = arr.drop(3)

            # Remove the last index which is the date
            modified_arr.pop(1)

            # Result should be the poly_id and the split index (if it exists)
            if modified_arr.length > 1
                # return modified_arr.join("_")
                result[:poly_id] = modified_arr[0]
                result[:split_poly_id] = modified_arr.join("_")
            else
                # return modified_arr[0]
                result[:poly_id] = modified_arr[0]
                result[:split_poly_id] = modified_arr[0]
            end
        end

        return result
    end

    def self.build_split_folder path, index
        # if the index is null then it's the first loop, don't add an underscore
        if index.nil?
            if !File.directory?(path)
                return path
            else
                return FinalDeliverySplits.build_split_folder path, 1
            end
        else
            # check if the folder exists
            if File.directory?("#{path}_#{index}")
                return FinalDeliverySplits.build_split_folder path, index + 1
            else
                return "#{path}_#{index}"
            end
        end

        # if not then create it 
        # if it does then increment the index by one and call method again
    end

    def self.build_tile_index final_delivery_folder, project="SL"

        p "BUILD TILE INDEX"

        # # Testing
        # final_delivery_folder = "/vol1/Bernard_Test/Final_Delivery_20240906_AL/"
        # project = "SL"

        # geotag_path = "/vol3/24-6567_USDA_SL/03_FrameBase/WA/Tiles_Dump/Final_Delivery_20240731_WA/SL/"
        geotag_path = "#{final_delivery_folder}#{project}"

        p "geotag_path: #{geotag_path}"

        # Iterate 
        Dir.glob("#{geotag_path}/*").each do |folder|
            next if !File.directory?(folder)

            # # extract the folder name
            state_abv = Pathname(folder).each_filename.to_a[-1]

            p state_abv

            state = State.exclude_geom.find_by(abv: state_abv)

            Dir.glob("#{geotag_path}/#{state_abv}/*").each do |county_folder|

            # ["/vol2/226567_14_SL_NY/04_TilesDump/Final_Delivery_20221130_NY/SL/WA/36051/"].each do |county_folder|

                county_fips = Pathname(county_folder).each_filename.to_a[-1]

                county = state.counties.find_by(full_fips: county_fips)

                utm_indexes = {}

                p county_fips

                # Iterate the files in the folder
                Dir.glob("#{geotag_path}/#{state_abv}/#{county_fips}/Orthos/*.tif").each do |file|
                    # p file
                    next if file == '.' or file == '..'

                    # # Get the filename wihtout tif
                    filename_without_extension = File.basename(file, '.tif')

                    parsed_poly_id = FinalDeliverySplits.extract_id filename_without_extension, project

                    tile = Tile.ortho_processed.find_by(poly_id: parsed_poly_id[:poly_id])

                    p "-------"
                    p filename_without_extension
                    p parsed_poly_id
                    p "-------"

                    if tile.nil?
                        raise Exception, "Parsed PolyID \"#{parsed_poly_id[:poly_id]}\" not found in Database while building Tile Index"
                    end

                    # Get the UTM Zone
                    utm_zone = tile.utm_zone

                    # Create the property if it doesn't exist
                    utm_indexes[utm_zone] = [] if utm_indexes[utm_zone].nil?

                    # Push the file to the utm zone
                    utm_indexes[utm_zone] << file
                end

                p "+++++"
                p utm_indexes
                p "+++++"

                utm_indexes.each do |utm_key, utm|

                    # Generate the output tile index
                    if utm_indexes.count > 1
                        output_index_file = "#{geotag_path}/#{state_abv}/#{county_fips}/Orthos/ortho_index_#{state.abv}_#{county.full_fips}_15_4_z#{utm_key}"
                        # next
                    else
                        output_index_file = "#{geotag_path}/#{state_abv}/#{county_fips}/Orthos/ortho_index_#{state.abv}_#{county.full_fips}_15_4"
                        # next
                    end

                    # # Remove the shapefile if it already exists
                    File.delete("#{output_index_file}.shp") if File.exist?("#{output_index_file}.shp")
                    File.delete("#{output_index_file}.dbf") if File.exist?("#{output_index_file}.dbf")
                    File.delete("#{output_index_file}.prj") if File.exist?("#{output_index_file}.prj")
                    File.delete("#{output_index_file}.shx") if File.exist?("#{output_index_file}.shx")

                    p "---------------"
                    p county.full_fips
                    p "gdaltindex -t_srs EPSG:269#{utm_key} #{output_index_file}.shp '#{utm.join("' '")}'"

                    # # Create the tileindex
                    response = system("gdaltindex -t_srs EPSG:269#{utm_key} #{output_index_file}.shp '#{utm.join("' '")}'")

                    p "gdaltindex"
                    p response
                    p "---------------"

                end

            end
        end

    end

end