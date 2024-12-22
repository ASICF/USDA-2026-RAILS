class FinalDeliverySplits

    def self.preprocessing input_directory='P:\Vol_1\Bernard_Test', packing_slip=PackingSlip.find(144), current_user = User.first

        output = {
            count: 0,
            pass: false,
            errors: []
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

        if !File.directory?(final_delivery_folder)

            # => If no Big Tile then just cancel the process
            output[:message] = "Final Delivery Folder '#{final_delivery_folder}' in #{split_folder}"
            output[:pass] = false

            return output
        end

        # Check the user supplied path
        # => Make sure it's all scoped under the project folder
        # => Check if the Big Tiles folder exists

        if !File.directory?(split_folder)

            # => Create the Big Tiles folder if it doesn't exist
            FileUtils.mkdir_p(split_folder)

            # => If no Big Tile then just cancel the process
            output[:message] = "No splits found in #{split_folder}"
            output[:pass] = false

            return output
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
                        output[:errors] << "#{filename} Does Not have 4th Band"
                    end

                    # check if the tiff is projected
                    listgeo_response = `listgeo '#{split_folder}/#{filename}'`
                    output[:errors] << "#{filename} does Not have GTCitationGeoKey. Check if the Tiff is projected." if !listgeo_response.include? "GTCitationGeoKey"
                    output[:errors] << "#{filename} does Not have PCSCitationGeoKey. Check if the Tiff is projected." if !listgeo_response.include? "PCSCitationGeoKey"

                else
                    # filename does not exist within the county foulder
                    output[:errors] << "#{filename} Does not exist within #{final_delivery_folder}/#{project}/#{tile.state_abv}/#{tile.county.full_fips}/Orthos"
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

        # If the verified splits is not empty and there are no unmatched 
        if verified_splits.length > 0 && output[:errors].length == 0
            p "ALL GOOD DUDE"
            # FinalDelivery.delay.nrisl_execute params, current_user, path
            FinalDeliverySplits.processing verified_splits, packing_slip, split_folder, final_delivery_folder, current_user
        end

        # return to client
        return output

    end

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

    def self.processing verified_splits, packing_slip, split_folder, final_delivery_folder, current_user

        p "------------"
        p "Processing"
        p packing_slip
        p "split_folder: #{split_folder}"
        p "final_delivery_folder: #{final_delivery_folder}"
        pp verified_splits
        p "------------"

        # Create the folder structure 
        # => OriginalSplit
        # => ToDelete
        # => ToMove

        # check if the packing slip folder already exists within the splits folder

        # Get the folder friendly file name
        psn_folder_name = packing_slip.name.gsub(/[^\w\s_-]+/, '').gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2').gsub(/\s+/, '_')

        # Create subfolders
        to_delete_path = "#{split_folder}/#{psn_folder_name}/toDelete"
        original_path = "#{split_folder}/#{psn_folder_name}/originalSplit"
        to_move_path = "#{split_folder}/#{psn_folder_name}/toMove"

        # track where files are moved so they don't need to be parsed out again
        original_arr = []
        delete_arr = []
        move_arr = []

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

            # arr = File.basename(file, '.tif').split("_")

            # final_poly_id = arr[3]
            # original_poly_id = arr[3]

            # if arr.size == 6
            #     final_poly_id = "#{arr[3]}_#{arr[4]}"
            #     original_poly_id = arr[3]

            #     if Tile.find_by(filename: filename_without_extension).present?
            #         original_poly_id = "#{arr[3]}_#{arr[4]}"
            #     end

            # elsif arr.size == 7
            #     final_poly_id = "#{arr[3]}_#{arr[4]}_#{arr[5]}"
            #     original_poly_id = "#{arr[3]}_#{arr[4]}"
            # end

            # p "Filename: #{filename_without_extension}"
            # p "original poly_id: #{original_poly_id}"

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

            # # copy the metadata file to the folder and rename it
            # FileUtils.cp("#{to_delete_path}/#{county_fips}/#{tile.filename}.xml", "#{to_move_path}/#{county_fips}/#{filename_without_extension}.xml")

            # # Read the template file
            # metadata_text = File.read("#{to_move_path}/#{county_fips}/#{filename_without_extension}.xml")

            # # check if the metadata file is valid
            # if metadata_text.scan(">#{parsed_poly_id[:poly_id]}<").count == 0
            #     raise Exception, "#{"#{to_move_path}/#{county_fips}/#{filename_without_extension}.xml"}: Could not find matching poly_id #{parsed_poly_id[:poly_id]} in copied metadata"
            # end

            # # Update the variables
            # metadata_text = metadata_text.gsub(parsed_poly_id[:poly_id], final_poly_id)

            # # Write the text to the county folder as a new text file
            # File.open("#{to_move_path}/#{county_fips}/#{filename_without_extension}.xml", "w") {|file| file.puts metadata_text }

            # # cut and paste the file to a new folder
            # FileUtils.mv("#{path}/#{filename_without_extension}.tif", "#{to_move_path}/#{county_fips}/")
            # FileUtils.mv("#{path}/#{filename_without_extension}.tfw", "#{to_move_path}/#{county_fips}/")

        end

        p "----------"
        pp original_arr
        pp delete_arr
        pp move_arr
        p "----------"


        # p FinalDeliverySplits.cleanup verified_splits, psn_folder_name, to_delete_path, original_path, to_move_path

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

    def self.migration
        # Iterate the county Folders in the ToMove folder into the County folder of the Final Delivery

        # build the Tile Index once completed
    end

    def self.build_tile_index
        # Connect to the Final Delivery build tile index method
    end

    def self.validation
        # Pass to the Final Delivery Validation
    end

    def self.cleanup verified_splits="", psn_folder_name="", to_delete_path="", original_path="", to_move_path=""
        # Runs if the script fails
        # => Copy the original tile from the ToDelete to it's county folder in the Final Delivery
        # => Copy the split tiles from OriginalSplit into the Big Tiles folder

        verified_splits = [
            "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_10_20240820",
            "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_9_20240820",
            "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_8_20240820",
            "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_7_20240820",
            "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_6_20240820",
            "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_5_20240820",
            "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_4_20240820",
            "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_3_20240820",
            "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_2_20240820",
            "/vol1/Bernard_Test/Big_Tiles/ortho_AL_15_7341010700H6BB000c_1_20240820"
        ]
        psn_folder_name = "20240906_AL"
        to_delete_path = "/vol1/Bernard_Test/Big_Tiles/20240906_AL/toDelete"
        original_path = "/vol1/Bernard_Test/Big_Tiles/20240906_AL/originalSplit"
        to_move_path = "/vol1/Bernard_Test/Big_Tiles/20240906_AL/toMove"

        p "CLEANUP"

        # check if the to_delete_path, original_path, to_move_path exist
        if !File.directory?(to_delete_path) || !File.directory?(original_path) || !File.directory?(to_move_path)
            p "Missing intermediate file paths"
        end

        # iterate the tiles inside the to_delete_path and move back to final delivery folder
        # Dir.glob("#{to_delete_path}/**/*.tif").each do |file|
        #     p file
        # end


        Dir.glob("#{to_delete_path}/*").each do |folder|
            p folder

            state_abv = Pathname(folder).each_filename.to_a[-1]
            p Pathname(folder)
            p state_abv

        end

        # Iterate the tiles in the original split
        # Dir.glob("#{original_path}/**/*.tif").each do |file|
        #     p file
        # end
    end

end