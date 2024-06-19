class FinalDelivery < ApplicationRecord
    require 'csv'

    def self.nrisl_validate_files params, current_user

        # Check that the folder exists
        # Get all completed counties 
        project = params[:project]
        counties = {}
        output = {
            project: project,
            input_directory: params[:input_directory],
            pass: false,
            count: 0,
            result: []
        }

        path = Task.build params[:input_directory]

        p "#{params[:input_directory]}/Big_Tiles"

        if !path
            output[:message] = "Invalid Input Directory: #{params[:input_directory]}" 
            return output
        end

        if !File.directory?("#{path}/Big_Tiles")
            output[:message] = "No folder called \"Big_Tiles\" found. Create folder to store splits and try again: #{params[:input_directory]}\\Big_Tiles"
            return output
        end

        # If the path can't build
        # raise Exception, "Invalid Input Directory: #{params[:input_directory]}" if !path
        # raise Exception, "No folder called \Big_Tiles\" found. Create folder to store splits and try again: #{params[:input_directory]}\\Big_Tiles" if !File.directory?("#{params[:input_directory]}/Big_Tiles")

        # get the active counties in the states
        state = State.includes(:tiles).find(params[:state_id])
        output[:state_id] = state.id

        error_path = "#{path}/Final_Delivery_Errors - #{Date.today.strftime("%F")}.txt"

        # Create folder in directory to store errors
        # error_file = File.new(error_path, "w")

        missing_tiles = []

        # iterate all files in folders
        Dir.glob("#{path}/*.tif").each do |file|

            filename = File.basename(file)
            filename_without_extension = File.basename(file, '.tif')

            # find the file in the database
            tile = state.tiles.find_by(filename: filename_without_extension, project: project)

            # throw error if Tile is not valid
            if tile.nil?
                diff_project = "NRI"

                # check if the tile is in the other project
                if project == "NRI"
                    diff_project = "SL"
                end

                # check if the file is in the wrong project
                if state.tiles.find_by(filename: filename_without_extension, project: diff_project).present?
                    return output[:message] = "Detected file #{filename} which is for #{diff_project}. Please move to appropriate file"
                else
                    missing_tiles << filename_without_extension
                    next
                end

            end

            # if there is a missing tile then just skip it
            next if missing_tiles.count > 0

            # Add to the total
            output[:count] += 1

            # check if the county id exists or not but only if there is no errors detected
            if counties[tile.county_id].nil?
                counties[tile.county_id] = {
                    id: tile.county_id,
                    county_name: tile.county_name,
                    state_name: tile.state_name,
                    full_fips: tile.county.full_fips,
                    total_tiles: state.tiles.where(county_id: tile.county_id, project: project).count,
                    ready_to_ship: state.tiles.flown.at_done.ortho_processed.dumped.not_shipped.where(county_id: tile.county_id, project: project).count,
                    total_shipped_tiles: state.tiles.shipped.where(county_id: tile.county_id, project: project).count,
                    folder_count: 1
                }
            else
                counties[tile.county.id][:folder_count] += 1
            end

        end

        if missing_tiles.count > 0

            output[:pass] = false
            output[:message] = "#{missing_tiles.count} Tiles were not found in the App: \"#{missing_tiles.join('", "')}\""
            
        elsif output[:count] > 0

            # Convert the has to an array of hashes
            counties.each do |key, value|
                output[:result] << value
            end

            output[:pass] = true
            output[:message] = "Validated #{output[:count]} tiles in #{params[:input_directory]}"

            return output
        else
            output[:message] = "Soemthing went wrong. No Tiles were found in #{params[:input_directory]}"
        end


        pp output

        "Done"

        return output

    end

    def self.nrisl_prepare params, current_user

        response = {
            pass: false,
            message: nil
        }

        path = nil
        project = params[:project]

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Build the path in linux
                path = Task.build params[:input_directory]

                # If the path can't build
                raise Exception, "Invalid Input Directory: #{params[:input_directory]}" if !path
        
                # Check if the path is a folder
                if !File.directory?(path)
                    raise Exception, "Invalid Path: #{path}"
                end

                # Check if the packing slip doesn't exist already
                psn = PackingSlip.find_by(name: params[:packing_slip_name])
                raise Exception, "Packing Slip already exists" if psn.present?

                # Check the delivery type
                if !["Production", "Pre-Production"].include?(params[:delivery_type])
                    raise Exception, "Invalid Delivery Type, must be \"Proudction\" or \"Pre-Production\"."
                end

                # Check the Coverage
                if !["Full Counties", "Partial Counties"].include?(params[:coverage])
                    raise Exception, "Invalid Coverage, must be \"Full Counties\" or \"Partial Counties\"."
                end

                # Find the state
                state = State.find_by(id:params[:state_id])
                if state.nil?
                    raise Exception, "No State Parameter found that is created"
                end

                # Check if the counties exist and have full tiles ready to ship (if marked as full counties)
                if params[:coverage] == "Full Counties"

                    # Get the counties scoped by the state
                    counties = state.counties.includes(:tiles).where(id: params[:counties])

                    # Check if the counties count matches the number of counties passed
                    if counties.count != params[:counties].count
                        raise Exception, "Could not find all selected counties in the app that were passed."
                    end

                    # Check if the tiles in the counties are marked as ready to ship
                    counties.each do |county|
                        # Check the ready to ship tile count
                        if county.tiles.where(project: project).count != county.tiles.flown.at_done.ortho_processed.dumped.not_shipped.where(project: project).count
                            raise Exception, "County #{county.name} totals do not match the ready to ship totals, make sure the tiles have been marked as dumped"
                        end
                    end

                end

                # p "-------------"
                # p "COUNTS"
                # p Dir.glob("#{path}/*.tif").count
                # p params[:count]
                # p "-------------"
        
                # Check if the number of files in the directory match the number of files in the db
                if Dir.glob("#{path}/*.tif").count != params[:count]
                    raise Exception, "Tiff count does not match previous query. New Tiffs were added since processing the first validation form."
                end

                response = {
                    pass: true,
                    message: "Text file has been uploaded to the server and supplied form has been validated. Import process has been added to Job Queue. You will receive a message when it is completed."
                }

            rescue Exception => exception
                Rails.logger.error "#{project} Final Delivery Prep Error: #{exception.message}"
                p "-----------"
                p exception.backtrace.count
                exception.backtrace.each do |x|
                    next if !x.include? "footprint.rb"
                    x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
                   p [$1,$2,$4]
                end
                p "-----------"

                response[:pass] = false
                response[:message] = [exception.message]

                raise ActiveRecord::Rollback
            end
        end

        if response[:pass] && path
            p "ALL GOOD DUDE"

            FinalDelivery.delay.nrisl_execute params, current_user, path
        end

        response

    end

    def self.nrisl_execute params, current_user, path

        p "--------------"
        p "FINAL DELIVERY"
        p params
        p path
        p "--------------"

        output = {
            pass: false,
            message: nil,
            count: 0,
            errors: [],
            result: nil,
            file_path: nil,
            psn: nil
        }
    
        count = 0
        current_time = Time.now
        delivery_type = params[:delivery_type]
        coverage = params[:coverage]
        psn = nil
        validation_path = params[:input_directory]
        project = params[:project]

        # Stores variables for the job process
        process_success = false
        error_message = "Something went wrong. Contact Programming."

        # Created new Job
        job = Job.create(
            started_at: Time.now,
            message: "Processing Request...",
            active: true,
            process_type: "#{project} Final Delivery",
            creator: current_user
        )

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Create a new History record
                history = History.new
                history.action_type = delivery_type == "Production" ? "Final Delivery" : "Final Delivery (Pre-Production)"
                history.creator = current_user
                history.save

                # if the path does not exist then throw error
                raise Exception, "Invalid Input Directory: #{params[:input_directory]}" if !path

                # check if the path is a valid direcotry
                raise Exception, "Invalid Path: #{path}" if !File.directory?(path)

                # # Check if the number of files in the directory match the number of files in the db
                if Dir.glob("#{path}/*.tif").count != params[:count]
                    raise Exception, "Tiff count does not match previous query. New Tiffs were added since processing the first validation form."
                end

                # Set the default final delivery folder to be preproduction
                psn_folder_name = "Preproduction_Sample_#{Date.today.strftime("%F")}"

                # get the state
                state = State.find_by(id: params[:state_id])

                # Check if production
                # => If so then create a packing slip
                if delivery_type == "Production"

                    # Build a new packing slip
                    psn = PackingSlip.new(name: params[:packing_slip_name], shipped_date: Time.now, project: project, state: state, state_abv: state.abv)

                    # If the packing slip exists then abort
                    # => If not then create a new packing slip
                    if !psn.save
                        raise Exception, "Error saving Packing Slip: #{psn.errors.full_messages.to_sentence}"
                    end

                    # Make sure the folder name is safe
                    psn_folder_name = psn.name.gsub(/[^\w\s_-]+/, '').gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2').gsub(/\s+/, '_')

                    # set the packing slip id
                    output[:psn] = psn.id

                end

                # Create the geotag output
                final_delivery_path = "#{path}/Final_Delivery_#{psn_folder_name}/#{project}"

                # build the validation path for later
                validation_path = "#{params[:input_directory]}\\Final_Delivery_#{psn_folder_name}\\#{project}"

                # Create the final delivery path
                FileUtils.mkdir_p final_delivery_path

                # Get the filename
                # file_name = File.basename(params[:content_file], '.txt')

                Tile.where(county_id: params[:counties], state_id: state.id, project: project).each do |tile|

                    # p "+++++++++"
                    # p tile.id
                    # p "+++++++++"

                    # Skip the tile if the coverage type is partial and the tile is not ready to ship
                    next if coverage == "Partial Counties" && !tile.ready_to_ship

                    # check if the tile's states have been satisfied. 
                    # => if not then abort the process
                    raise Exception, "Tile (#{tile.poly_id}) does not have a Filename" if tile.filename.nil?
                    raise Exception, "Tile (#{tile.poly_id}) does not have a Flight Date" if !tile.flown
                    raise Exception, "Tile (#{tile.poly_id}) does not have the AT Done Date set" if !tile.at_done
                    raise Exception, "Tile (#{tile.poly_id}) does not have the Ortho Processing Date set" if !tile.ortho_processing
                    raise Exception, "Tile (#{tile.poly_id}) does not have the Tile Dump Date set" if !tile.dumped

                    # Throw error if tile's file is not found in folder
                    raise Exception, "File #{tile.filename}.tif does not exist in folder #{params[:input_directory]}" if !File.file?("#{path}/#{tile.filename}.tif")

                    # add the filename with extension
                    filename = "#{tile.filename}.tif"

                    # Get the filename without the extension
                    filename_without_extension = tile.filename

                    # Rebuild the midean flight date time
                    tile.generate_median_flight_date_time

                    # Check if the Median Flight Date Time is set
                    if tile.median_flight_date_time.nil? 
                        raise Exception, "Tile (#{tile.poly_id}) has no Median Flight Date Time"
                    end

                    # Get the extents of the bounding box
                    sql = "SELECT ST_XMin(geom::geometry) as x_min, 
                        ST_XMax(geom::geometry) as x_max, 
                        ST_YMin(geom::geometry) as y_min, 
                        ST_YMax(geom::geometry) as y_max FROM tiles where id = #{tile.id}"

                    extent_results = ActiveRecord::Base.connection.execute(sql)

                    # Get the current time
                    current_time = Time.now

                    # Double check values exist
                    if tile.plane.nil?
                        raise Exception, "Tile #{tile.poly_id} does not have an associated Plane"
                    elsif tile.camera.nil?
                        raise Exception, "Tile #{tile.poly_id} does not have an associated Plane"
                    elsif tile.median_flight_date_time.nil?
                        raise Exception, "Tile #{tile.poly_id} does not have a Median Flight Date Time"
                    elsif extent_results.blank?
                        raise Exception, "Tile #{tile.poly_id} Could not calculate the Min/Max Extents"
                    end

                    # get the image properties 
                    image_props = `identify -format "%W|%H" "#{path}/#{filename}"`.split('|')
                    
                    # Update the tile with the rows/columns
                    tile.update(
                        rows: image_props[0],
                        columns: image_props[1],
                    )

                    # Create County folder if it doesn't exist
                    county_path = "#{final_delivery_path}/#{tile.state.abv}/#{tile.county.full_fips}/Orthos"
                    FileUtils.mkdir_p(county_path) unless File.directory?(county_path)

                    # Generate the metadata for the tif
                    template = "#{Rails.root}/assets/2024_SL_Template.xml"
                    if project == "NRI"
                        template = "#{Rails.root}/assets/2024_NRI_Template.xml"
                    end

                    # Read the template file
                    template_text = File.read(template)

                    # Update the variables
                    template_text = template_text.gsub('[tile_name_without_tif]', filename_without_extension)
                    template_text = template_text.gsub('[date_today]', current_time.strftime("%F"))
                    template_text = template_text.gsub('[polyid]', tile.easement.poly_id)
                    template_text = template_text.gsub('[state_abv]', tile.state.abv)
                    template_text = template_text.gsub('[county_name]', tile.county.name)
                    template_text = template_text.gsub('[FIPS]', tile.county.full_fips)
                    template_text = template_text.gsub('[xmin]', extent_results[0]["x_min"].to_s)
                    template_text = template_text.gsub('[xmax]', extent_results[0]["x_max"].to_s)
                    template_text = template_text.gsub('[ymin]', extent_results[0]["y_min"].to_s)
                    template_text = template_text.gsub('[ymax]', extent_results[0]["y_max"].to_s)
                    template_text = template_text.gsub('[flightdate]', tile.flight_date.strftime("%Y-%m-%d"))
                    template_text = template_text.gsub('[flightdatetime]', tile.median_flight_date_time.strftime("%Y-%m-%dT%H:%M:%SZ"))
                    template_text = template_text.gsub('[aircraft]', tile.plane.model)
                    template_text = template_text.gsub('[tail_number]', tile.plane.name)
                    template_text = template_text.gsub('[camera_name]', tile.camera.name)
                    template_text = template_text.gsub('[columns]', tile.columns.to_s)
                    template_text = template_text.gsub('[rows]', tile.rows.to_s)
                    template_text = template_text.gsub('[zone]', tile.utm.zone.to_s)

                    # Write the text to the county folder as a new text file
                    File.open("#{county_path}/#{filename_without_extension}.xml", "w") {|file| file.puts template_text }

                    # Set the GeoTIF tags
                    # 1. Create the GTF file for the tf
                    gtf_file = "#{county_path}/#{filename_without_extension}.gtf"

                    # # 2. Output the listgeo command to a GTF File
                    listgeo_response = system("listgeo '#{path}/#{filename}' > '#{gtf_file}'")

                    # update the gtf file
                    FinalDelivery.build_gtf gtf_file, filename_without_extension, tile.utm.zone, tile.poly_id

                    # Update the Tiff tags and copy to the county folder
                    geotif_response = system("geotifcp -g '#{gtf_file}' '#{path}/#{filename}' '#{county_path}/#{filename}'")

                    # Copy the tfw file
                    FileUtils.cp("#{path}/#{filename_without_extension}.tfw", "#{county_path}/#{filename_without_extension}.tfw")

                    if project === "SL"
                        image_description = "'TIFFTAG_IMAGEDESCRIPTION=USDA-FSA-NRCS-Stewardship Lands-#{tile.state.name}-under FPAC-BC contract 47QTCA18D004Z'"
                    elsif project === "NRI"
                        image_description = "'TIFFTAG_IMAGEDESCRIPTION=USDA-FSA-NRCS-National Resource Inventory-#{tile.state.name}-under FPAC-BC contract 47QTCA18D004Z'"
                    end

                    # Create the GeoTIFF Tags
                    response_1 = system("python /usr/bin/gdal_edit.py -mo #{image_description} '#{county_path}/#{filename}'")
                    # p response_1

                    response_2 = system("python /usr/bin/gdal_edit.py -mo 'TIFFTAG_DOCUMENTNAME=#{tile.easement.poly_id}' '#{county_path}/#{filename}'")
                    # p response_2

                    # Check the responses
                    if !response_1 || !response_2
                        raise Exception, "Could not calculate the Tiff Tag for #{params[:input_directory]}/#{filename}"
                    end

                    if delivery_type == "Production"

                        # Update the tiles with the packing slip info
                        tile.update!(
                            ship_date: psn.shipped_date,
                            packing_slip: psn,
                            psn: psn.name
                        )

                    end

                    # Add the tile to the history record
                    history.tiles << tile

                    # Incremeent the count
                    output[:count] += 1

                    # Delete the GTF File from the county folder
                    File.delete(gtf_file) if File.exist? gtf_file

                end

                # check the county and abort if no values
                if output[:count] == 0
                    raise Exception, "No Tiles were found and marked as shipped."
                end

                # Iterate the county folder and build the tile index
                Dir.glob("#{final_delivery_path}/*").each do |folder|
                    next if !File.directory?(folder)

                    # # extract the folder name
                    state_abv = Pathname(folder).each_filename.to_a[-1]

                    # p state_abv

                    state = State.exclude_geom.find_by(abv: state_abv)

                    Dir.glob("#{final_delivery_path}/#{state_abv}/*").each do |county_folder|
                        county_fips = Pathname(county_folder).each_filename.to_a[-1]

                        county = state.counties.find_by(full_fips: county_fips)

                        utm_indexes = {}

                        # p county_fips

                        # Iterate the files in the folder
                        Dir.glob("#{final_delivery_path}/#{state_abv}/#{county_fips}/Orthos/*.tif").each do |file|
                            p file
                            next if file == '.' or file == '..'

                            # Get the filename wihtout tif
                            filename = File.basename(file, '.tif')

                            # Get the UTM Zone
                            utm_zone = Tile.includes(:utm).find_by(filename: filename).utm.zone

                            # Create the property if it doesn't exist
                            utm_indexes[utm_zone] = [] if utm_indexes[utm_zone].nil?

                            # Push the file to the utm zone
                            utm_indexes[utm_zone] << file
                        end

                        # p utm_indexes

                        utm_indexes.each do |utm_key, utm|

                            # Generate the output tile index
                            if utm_indexes.count > 1
                                output_index_file = "#{final_delivery_path}/#{state_abv}/#{county_fips}/Orthos/ortho_index_#{state.abv}_#{county.full_fips}_15_4_z#{utm_key}.shp"
                            else
                                output_index_file = "#{final_delivery_path}/#{state_abv}/#{county_fips}/Orthos/ortho_index_#{state.abv}_#{county.full_fips}_15_4.shp"
                            end

                            # Create the tileindex
                            response = system("gdaltindex -t_srs EPSG:269#{utm_key} '#{output_index_file}' '#{utm.join("' '")}'")

                        end

                    end
                end

                # if reached this point then mark it as passed
                output[:pass] = true

                # Assume Production
                message = "Successfully processed #{output[:count]} Tifs in #{params[:counties].size} Full Counties for #{state.name} in #{params[:input_directory]}. Validation process was executed and follow up email will be sent."

                if coverage == "Partial Counties"
                    message = "Successfully processed #{output[:count]} Tifs in #{params[:counties].size} Partial Counties for #{state.name} in #{params[:input_directory]}. Validation process was executed and follow up email will be sent."
                end

                # Update the message of the history
                history.update(message: message)

                # Update the job
                job.update(
                    finished_at: Time.now,
                    success: true,
                    active: false,
                    message: message
                )

                # Log and send email
                Mailbox.ship({
                    users: MailGroup.find_by(name: "Final Delivery").users | [current_user],
                    subject: "#{project} #{delivery_type} Final Delivery Finished Successfully",
                    message: message,
                    route: delivery_type == "Production" ? Rails.application.routes.url_helpers.packing_slip_worksheet_url(psn, only_path: false, host: Rails.application.secrets.host) : nil
                })

                # Update the process
                process_success = true

            rescue Exception => exception
                Rails.logger.error "Final Delivery Error: #{exception.message}"
                error_message = exception.message
                p "-----------"
                p exception.backtrace.count
                exception.backtrace.each do |x|
                    next if !x.include? "footprint.rb"
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

        # Run if the process failed
        if !process_success

            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Final Delivery").users | [current_user],
                subject: "#{project} Final Delivery Failed",
                message: "#{project} Final Delivery Failed, error encountered is listed below: <br/><br/>#{error_message}".html_safe
            })

            # Update the Job
            job.update(
                finished_at: Time.now,
                active: false,
                success: false,
                message: "#{project} Final Delivery Failed",
                error_message: error_message
            )
        else
            # pass to the final delivery validation
            FinalDelivery.validate_deliverable validation_path, psn, current_user

            # Check for splits
            FinalDelivery.check_for_splits params[:input_directory], psn, current_user
        end

        output

    end

    def self.validate_deliverable input_directory, packing_slip, current_user

        # Verify the path
        # iterate all xml files
        # verify the tile is in the packing slip
        # verify the .tif and .tfw exist
        # validate the xml file
        # make sure all tiles that are associated to the packing slip are found in the final delivery folder

        # get the path from the input directory
        path = Task.build input_directory
        project = packing_slip.project
        
        # if no path is built then abort the process and send email
        if !path
            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Final Delivery").users | [current_user],
                subject: "#{project} Final Delivery Validation Failed",
                message: "Final Delivery Valdiation failed due to the supplied path not existing: #{input_directory}. Please verify and try again.",
            })
            return
        end

        # Create a new History record
        history = History.new
        history.action_type = "#{project} Final Delivery Validation"
        history.creator = current_user
        history.save

        psn_poly_ids = []
        psn_folder_name = "PreProduction"

        # Do a check for packing slip since it could be a pre-production sample
        if packing_slip
            p "FOUND PACKING SLIP"

            # Make sure the folder name is safe
            psn_folder_name = packing_slip.name.gsub(/[^\w\s_-]+/, '').gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2').gsub(/\s+/, '_')

            # Add a check to make sure all the tiles in the final delivery are in the packing slip
            psn_poly_ids = packing_slip.tiles.where(project: project).pluck(:poly_id)
        end

        # set the filename and path
        error_filename = "Final_Delivery_Validation_#{psn_folder_name} - #{Date.today.strftime("%F")}.txt"
        error_path = "#{path}/#{error_filename}"

        # Create folder in directory to store errors
        error_file = File.new(error_path, "w")

        # Track counts
        valid_count = 0
        error_count = 0

        # Iterate over all the xmls in the folder
        Dir.glob("#{path}/**/*.xml").each do |file|

            file_errors = []

            file_path = File.dirname(file)

            # Get the filename
            filename_without_extension = File.basename(file, '.xml')

            # split the filename into an array
            filename_arr = filename_without_extension.split("_")

            # get the poly_id without the extension if it was split
            poly_id = filename_arr[3]

            # if filename_without_extension == "ortho_MA_15_7313209800H0ZA0007_A_20241004"
            #     poly_id = "7313209800H0ZA0007_A"
            # elsif filename_without_extension == "ortho_MA_15_7313209800H0ZA0007_B_20241005"
            #     poly_id = "7313209800H0ZA0007_B"
            # elsif filename_without_extension == "ortho_ND_15_ND_08_WAHL_20240629"
            #     poly_id = "ND_08_WAHL"
            # end

            # Get the tile but if no packing slip then don't include it
            if packing_slip
                tile = Tile.shipped.find_by(poly_id: poly_id, packing_slip_id: packing_slip.id, project: project)
            else
                tile = Tile.find_by(poly_id: poly_id)
            end

            # do a check to see if the 3rd and 4th index joined with an underscore are a tile instead
            if tile.nil?

                poly_id = "#{filename_arr[3]}_#{filename_arr[4]}"

                if packing_slip
                    tile = Tile.shipped.find_by(poly_id: poly_id, packing_slip_id: packing_slip.id, project: project)
                else
                    tile = Tile.find_by(poly_id: poly_id)
                end
            end

            # check if the tile exists
            if tile.nil?
                if packing_slip
                    if Tile.shipped.find_by(poly_id: poly_id, packing_slip_id: packing_slip.id).present?
                        error_file.puts("#{filename_without_extension} - Tile (#{poly_id}) is not in the #{project}!\n")
                    else
                        error_file.puts("#{filename_without_extension} - Tile (#{poly_id}) does not exist in packing slip\n")
                    end
                else
                    error_file.puts("#{filename_without_extension} - Tile (#{poly_id}) does not exist in app\n")
                end
                error_count += 1
                next
            end

            # remove the poly_id from the packing slip poly_id array
            psn_poly_ids = psn_poly_ids - [tile.poly_id]

            # If the file has been split then 
            modified_poly_id = filename_arr.size == 6 ? "#{filename_arr[3]}_#{filename_arr[4]}" : filename_arr[3]

            file_errors << "No TIF Found" if !File.file?("#{file_path}/#{filename_without_extension}.tif")
            file_errors << "No TFW Found" if !File.file?("#{file_path}/#{filename_without_extension}.tfw")

            # read the contents of the metadata file
            metadata = File.read(file)

            file_errors << "must be 2 matches (#{modified_poly_id}) in xml completely enclosed by brackets (> <)" if metadata.scan(">#{modified_poly_id}<").count != 1
            file_errors << "must be 4 matches (#{modified_poly_id}) in xml" if metadata.scan("#{modified_poly_id}").count != 4
            file_errors << "must be 2 filenames in xml" if metadata.scan(">#{filename_without_extension}<").count != 3

            # get the listgeo response
            listgeo_response = `listgeo '#{file_path}/#{filename_without_extension}.tif'`
            # p "#{filename_without_extension} : #{listgeo_response}"

            file_errors << "Does Not have GTCitationGeoKey" if !listgeo_response.include? "GTCitationGeoKey"
            file_errors << "Does Not have PCSCitationGeoKey" if !listgeo_response.include? "PCSCitationGeoKey"
            file_errors << "Invalid UTM Zone found, should be zone #{tile.utm_zone}" if !listgeo_response.include? "PCS_NAD83_UTM_zone_#{tile.utm_zone}"
            # file_errors << "Invalid UTM Zone, should be zone #{tile.utm_zone}" if !listgeo_response.include? "NAD83 / UTM zone #{tile.utm_zone}"

            # validate the gtcitationgeokey
            gt_citation_match = 'GTCitationGeoKey (Ascii,'+(filename_without_extension.size + 1).to_s+'): "'+filename_without_extension+'"'

            # Check if the gt_citation_match is within the gtf file
            if !listgeo_response.include? gt_citation_match
                file_errors << "GTCitationGeoKey (#{gt_citation_match}) does not match GTF"
            end

            # Match based on Zones
            if tile.utm.zone == 10                                      
                pcs_citation_match = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 10N"'
            elsif tile.utm.zone == 11                                      
                pcs_citation_match = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 11N"'
            elsif tile.utm.zone == 12                                      
                pcs_citation_match = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 12N"'
            elsif tile.utm.zone == 13                                      
                pcs_citation_match = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 13N"'
            elsif tile.utm.zone == 14
                pcs_citation_match = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 14N"'
            elsif tile.utm.zone == 15
                pcs_citation_match = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 15N"'
            elsif tile.utm.zone == 16
                pcs_citation_match = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 16N"'
            elsif tile.utm.zone == 17
                pcs_citation_match = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 17N"'
            elsif tile.utm.zone == 18
                pcs_citation_match = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 18N"'
            elsif tile.utm.zone == 19
                pcs_citation_match = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 19N"'
            elsif tile.utm.zone == 20
                pcs_citation_match = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 20N"'
            elsif tile.utm.zone == 4
                pcs_citation_match = 'PCSCitationGeoKey (Ascii,20): "NAD83 / UTM zone 4N"'
            elsif tile.utm.zone == 5
                pcs_citation_match = 'PCSCitationGeoKey (Ascii,20): "NAD83 / UTM zone 5N"'
            else
                pcs_citation_match = nil
                file_errors << "Does not have a valid PSCitationGeoKey!"
            end

            # Check if the pcs_citation_match is within the gtf file
            if pcs_citation_match && !listgeo_response.include?(pcs_citation_match)
                file_errors << "PCSCitationGeoKey (#{pcs_citation_match}) does not match GTF"
            end

            # Check out the gdalinfo 
            gdalinfo_response = `gdalinfo "#{file_path}/#{filename_without_extension}.tif"`

            # check if it has 4 band
            file_errors << "Does Not have 4th Band" if !gdalinfo_response.include? "Band 4" 

            # check for errors
            if file_errors.size > 0
                file_errors.each do |error|
                    error_file.puts("#{filename_without_extension} - #{error}\n")
                    error_count += 1
                end
            else
                valid_count += 1
                # add to the history
                history.tiles << tile
            end

        end

        # check that the psn poly_ids are empty
        # => if not then add them to the error file
        if psn_poly_ids.size > 0
            psn_poly_ids.each do |poly_id|
                error_file.puts("#{poly_id} - Missing Tile associated to Packing Slip not found in Final Delivery Folder\n")
                error_count += 1
            end
        end

        # close the file
        error_file.close

        # Set the Default response
        if packing_slip
            subject = "#{project} Final Delivery Validation Failed"
            message = "No Tiles were validated in #{input_directory} for Packing Slip \"#{packing_slip.name}\""
        else
            subject = "#{project} Pre-Production Final Delivery Validation Failed"
            message = "No Tiles were validated in #{input_directory} for Pre-Production Final Delivery"
        end

        # check for errors, then success, then all else
        if error_count > 0
            # Add check for packing slip
            if packing_slip
                subject = "#{project} Final Delivery Validation Failed"
                message = "#{error_count} Errors were encountered while validating Packing Slip \"#{packing_slip.name}\" in #{input_directory}. Check the Error Text File at #{error_path}"
            else
                subject = "#{project} Pre-Production Final Delivery Validation Failed"
                message = "#{error_count} Errors were encountered while validating Pre-Production Final Delivery in #{input_directory}. Check the Error Text File at #{error_path}"
            end
        elsif valid_count > 0
            # add check for packing slip
            if packing_slip
                subject = "#{project} Final Delivery Validation Succeeded"
                message = "Validated #{valid_count} Delvierables in #{input_directory} for Packing Slip \"#{packing_slip.name}\""
            else
                subject = "#{project} Pre-Production Final Delivery Validation Succeeded"
                message = "Validated #{valid_count} Delvierables in #{input_directory} for Pre-Production Final Delivery"
            end

            # if no errors then delete the error file
            File.delete(error_path) if File.exists? error_path
        end

        # add the tiles to the history
        history.update(message: message)

        # Log and send email
        Mailbox.ship({
            users: MailGroup.find_by(name: "Final Delivery").users | [current_user],
            subject: subject,
            message: message,
        })

    end

    def self.check_for_splits tile_dump_path, packing_slip, current_user

        # Takes the path and the packing slip
        # Checks for a "Big_Tiles" folder
        # iterates the tiffs in the most root directory, no recursive
        # Verifies
        # => Does the Poly ID exist?
        # => Does it exist in this packing slip?
        # => Does it exist in a packing slip already marked as shipped?
        # Send email notifying Final Delivery Group

        # get the path from the input directory
        path = Task.build tile_dump_path
        project = packing_slip.project
        
        # if no path is built then abort the process and send email
        if !path
            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Final Delivery").users | [current_user],
                subject: "#{project} Final Delivery Check for Splits Failed",
                message: "Final Delivery Split Checker failed due to the supplied path not existing: #{tile_dump_path}. Please verify and try again.",
            })
            return
        end

        split_tiles_path = "#{path}/Big_Tiles"
        p split_tiles_path

        # check that the Big_Tiles folder exists
        if !File.directory?(split_tiles_path)
            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Final Delivery").users | [current_user],
                subject: "#{project} Final Delivery Check for Splits Failed",
                message: "Final Delivery Split Checker failed because no \'Big_Tiles\" Folder exists in #{tile_dump_path}. Please update filename if there is a split folder.",
            })
            return
        end

        # Iterate all tiffs in the folder and extract the poly id

        validation_errors = []
        validation_error_poly_ids = []
        need_to_be_split = []

        Dir.glob("#{split_tiles_path}/*.tif").each do |file|

            path = File.dirname(file)
            # filename = File.basename(file)
            filename_without_extension = File.basename(file, '.tif')

            arr = File.basename(file, '.tif').split("_")

            final_poly_id = arr[3]
            original_poly_id = arr[3]

            if arr.size == 6
                final_poly_id = "#{arr[3]}_#{arr[4]}"
                original_poly_id = arr[3]

                if Tile.find_by(filename: filename_without_extension, project: project).present?
                    original_poly_id = "#{arr[3]}_#{arr[4]}"
                end

            elsif arr.size == 7
                final_poly_id = "#{arr[3]}_#{arr[4]}_#{arr[5]}"
                original_poly_id = "#{arr[3]}_#{arr[4]}"
            end

            # Validation

            # Does the Poly ID exist?
            tile_exists = Tile.find_by(poly_id: original_poly_id, project: project)

            if tile_exists.nil? && !validation_error_poly_ids.include?(original_poly_id)
                validation_error_poly_ids << original_poly_id
                validation_errors << "Tile \"#{original_poly_id}\" Does not exist in the system"
            end

            if tile_exists.packing_slip_id

                # Does it exist in a packing slip already marked as shipped?
                if tile_exists.packing_slip.id != packing_slip.id
                    validation_errors << "Tile \"#{original_poly_id}\" is assigned to Shipped PSN \"#{tile.packing_slip.name}\" but is still in \#{split_tiles_path}\" Folder. Possibly was missed during shipment."
                end
    
                # Does it exist in this packing slip?
                # tile = packing_slip.tiles.ortho_processed.dumped.shipped.find_by(poly_id: original_poly_id)
    
                # if tile.nil?
                #     validation_errors << ["Tile #{original_poly_id} Does not exist in the specified packing slip: #{packing_slip.name}"]
                # end

                # Find the tile in the packing slip
                tile = packing_slip.tiles.ortho_processed.dumped.shipped.find_by(poly_id: original_poly_id, project: project)

                need_to_be_split |= [tile.poly_id]

            end

        end
        
        # Build the needs to be split list
        needs_to_be_split_html = "<p>Below are the Tiles that need to be Split</p>"
        needs_to_be_split_html += '<ul>'
        need_to_be_split.each do |poly_id|
            needs_to_be_split_html += "<li>#{poly_id}</li>"
        end
        needs_to_be_split_html += '</ul>'

        # Build the validation error
        validation_error_html = "<p>Below are Validation Errors</p>"
        validation_error_html += '<ul>'
        validation_errors.each do |message|
            validation_error_html += "<li>#{message}</li>"
        end
        validation_error_html += '</ul>'

        # Send out Email
        subject = "#{project} Final Delivery Check for Splits Succeeded"
        message = nil

        # No splits and not validation errors
        if need_to_be_split.size == 0 && validation_errors.size == 0
            message = "No Splits or Validation Errors found in #{tile_dump_path} for #{packing_slip.name}"

        # Has splits to be made and no validation errors
        elsif need_to_be_split.size > 0 && validation_errors.size == 0
            message = "#{need_to_be_split.size} Splits Found and no Validation Errors found in #{tile_dump_path} for #{packing_slip.name}"
            message += "<hr/>"
            message += needs_to_be_split_html

        # Has no splits to be made and has validation errors
        elsif need_to_be_split.size == 0 && validation_errors.size > 0
            message = "No Splits Found but #{validation_errors.size} Validation Errors found in #{tile_dump_path} for #{packing_slip.name}"
            message += "<hr/>"
            message += validation_error_html

        # Has splits to be made and has validation errors
        elsif need_to_be_split.size > 0 && validation_errors.size > 0
            message = "#{need_to_be_split.size} Splits Found and #{validation_errors.size} Validation Errors found in #{tile_dump_path} for #{packing_slip.name}"
            message += "<hr/>"
            message += needs_to_be_split_html
            message += "<br/>"
            message += validation_error_html
        end

        # Log and send email
        Mailbox.ship({
            users: MailGroup.find_by(name: "Final Delivery").users | [current_user],
            subject: subject,
            message: message
        })
        return

    end

    def self.pass_to_validation

        # input_directory, packing_slip, current_user
        input_directory = "P:\\Vol_3\\24-6567_USDA_SL\\03_FrameBase\\PA\\Tiles_Dump\\Final_Delivery_20240620_PA"
        # P:\Vol_3\24-6567_USDA_SL\03_FrameBase\PA\Tiles_Dump\Final_Delivery_20240620_PA

        packing_slip = PackingSlip.find_by(name: "20240620_PA")

        current_user = User.admins.first

        # Pass to validator
        FinalDelivery.validate_deliverable input_directory, packing_slip, current_user

    end

    def self.fix_splits

        p "FIX SPLITS"

        ## Inputs
        # - Split folder
        # - Final Delivery Folder
        # - Test run (Boolean)

        # Set the Split Folder
        split_folder = "/vol3/24-6567_USDA_SL/03_FrameBase/PA/Tiles_Dump/Big_Tiles/"

        # Set the Final Delivery Folder
        final_delivery_folder = "/vol3/24-6567_USDA_SL/03_FrameBase/PA/Tiles_Dump/Final_Delivery_20240620_PA/"

        # Query the PackingSlip
        packing_slip = PackingSlip.find_by(name: "20240620_PA")

        # Throw error if the packing slip is not found
        raise Exception, "Could not find matching Packing Slip in the app: #{packing_slip.name}" if packing_slip.nil?

        # Get the first user
        current_user = User.first

        ## To Do
        # Recursively iterate the tifs in the Split folder
        # Extract the previous and updated poly_ids and county fullfips
        # Find the tif, tfw, and xml files in the final delivery folder
        # Copy the XML file to the Split folder
        # FInd and replace the poly id in the xml file
        # (After Test) Move the tif, tfw, and xml into toDelete folder oustide FInal Delivery

        # Get the folder friendly file name
        psn_folder_name = packing_slip.name.gsub(/[^\w\s_-]+/, '').gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2').gsub(/\s+/, '_')

        # Create subfolders
        to_delete_path = "#{split_folder}/#{psn_folder_name}/toDelete"
        original_path = "#{split_folder}/#{psn_folder_name}/originalSplit"
        to_move_path = "#{split_folder}/#{psn_folder_name}/toMove"

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

            arr = File.basename(file, '.tif').split("_")

            final_poly_id = arr[3]
            original_poly_id = arr[3]

            if arr.size == 6
                final_poly_id = "#{arr[3]}_#{arr[4]}"
                original_poly_id = arr[3]

                if Tile.find_by(filename: filename_without_extension).present?
                    original_poly_id = "#{arr[3]}_#{arr[4]}"
                end

            elsif arr.size == 7
                final_poly_id = "#{arr[3]}_#{arr[4]}_#{arr[5]}"
                original_poly_id = "#{arr[3]}_#{arr[4]}"
            end

            # p "Filename: #{filename_without_extension}"
            # p "original poly_id: #{original_poly_id}"

            # Find the tile in the packing slip
            tile = packing_slip.tiles.ortho_processed.dumped.shipped.find_by(poly_id: original_poly_id)

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
            if metadata_text.scan(">#{original_poly_id}<").count == 0
                raise Exception, "#{"#{original_path}/#{county_fips}/#{filename_without_extension}.xml"}: Could not find matching poly_id #{original_poly_id} in copied metadata"
            end

            # Update the variables
            metadata_text = metadata_text.gsub(original_poly_id, final_poly_id)

            # Write the text to the county folder as a new text file
            File.open("#{original_path}/#{county_fips}/#{filename_without_extension}.xml", "w") {|file| file.puts metadata_text }

            # cut and paste the file to a new folder
            FileUtils.mv("#{path}/#{filename_without_extension}.tif", "#{original_path}/#{county_fips}/")
            FileUtils.mv("#{path}/#{filename_without_extension}.tfw", "#{original_path}/#{county_fips}/")

            # Generate and update GTF File
            # Use geotifcp to create the tiff with updated headers to the toMove folder

            # Set the GeoTIF tags
            # 1. Create the GTF file for the tf
            gtf_file = "#{original_path}/#{county_fips}/#{filename_without_extension}.gtf"

            # 2. Output the listgeo command to a GTF File
            listgeo_response = system("listgeo '#{original_path}/#{county_fips}/#{filename_without_extension}.tif' > '#{gtf_file}'")

            # update the gtf file
            FinalDelivery.build_gtf gtf_file, filename_without_extension, tile.utm.zone, final_poly_id

            # Update the Tiff tags and copy to the county folder
            geotif_response = system("geotifcp -g '#{gtf_file}' '#{original_path}/#{county_fips}/#{filename_without_extension}.tif' '#{to_move_path}/#{county_fips}/#{filename_without_extension}.tif'")

            FileUtils.cp("#{original_path}/#{county_fips}/#{filename_without_extension}.tfw", "#{to_move_path}/#{county_fips}/#{filename_without_extension}.tfw")
            FileUtils.cp("#{original_path}/#{county_fips}/#{filename_without_extension}.xml", "#{to_move_path}/#{county_fips}/#{filename_without_extension}.xml")

            # # copy the metadata file to the folder and rename it
            # FileUtils.cp("#{to_delete_path}/#{county_fips}/#{tile.filename}.xml", "#{to_move_path}/#{county_fips}/#{filename_without_extension}.xml")

            # # Read the template file
            # metadata_text = File.read("#{to_move_path}/#{county_fips}/#{filename_without_extension}.xml")

            # # check if the metadata file is valid
            # if metadata_text.scan(">#{original_poly_id}<").count == 0
            #     raise Exception, "#{"#{to_move_path}/#{county_fips}/#{filename_without_extension}.xml"}: Could not find matching poly_id #{original_poly_id} in copied metadata"
            # end

            # # Update the variables
            # metadata_text = metadata_text.gsub(original_poly_id, final_poly_id)

            # # Write the text to the county folder as a new text file
            # File.open("#{to_move_path}/#{county_fips}/#{filename_without_extension}.xml", "w") {|file| file.puts metadata_text }

            # # cut and paste the file to a new folder
            # FileUtils.mv("#{path}/#{filename_without_extension}.tif", "#{to_move_path}/#{county_fips}/")
            # FileUtils.mv("#{path}/#{filename_without_extension}.tfw", "#{to_move_path}/#{county_fips}/")

        end

        # pass to the final delivery validation
        # FinalDelivery.validate_deliverable final_delivery_folder, packing_slip, current_user

        p "done"

    end

    def self.build_tile_index

        p "BUILD TILE INDEX"

        geotag_path = "/vol3/24-6567_USDA_SL/03_FrameBase/PA/Tiles_Dump/Final_Delivery_20240620_PA/SL/"

        # Iterate 
        Dir.glob("#{geotag_path}/*").each do |folder|
            next if !File.directory?(folder)

            # # extract the folder name
            state_abv = Pathname(folder).each_filename.to_a[-1]

            p state_abv

            state = State.exclude_geom.find_by(abv: state_abv)

            Dir.glob("#{geotag_path}/#{state_abv}/*").each do |county_folder|

            # ["/vol2/226567_14_SL_NY/04_TilesDump/Final_Delivery_20221130_NY/SL/PA/36051/"].each do |county_folder|

                county_fips = Pathname(county_folder).each_filename.to_a[-1]

                county = state.counties.find_by(full_fips: county_fips)

                utm_indexes = {}

                p county_fips

                # Iterate the files in the folder
                Dir.glob("#{geotag_path}/#{state_abv}/#{county_fips}/Orthos/*.tif").each do |file|
                    # p file
                    next if file == '.' or file == '..'

                    # Get the filename wihtout tif
                    filename = File.basename(file, '.tif')
                    arr = filename.split("_")

                    # p filename

                    final_poly_id = arr[3]
                    original_poly_id = arr[3]
        
                    if arr.size == 6
                        final_poly_id = "#{arr[3]}_#{arr[4]}"
                        original_poly_id = arr[3]
                    elsif arr.size == 7
                        final_poly_id = "#{arr[3]}_#{arr[4]}_#{arr[5]}"
                        original_poly_id = "#{arr[3]}_#{arr[4]}"
                    elsif arr.size == 8
                        final_poly_id = "#{arr[3]}_#{arr[4]}_#{arr[5]}"
                        original_poly_id = "#{arr[3]}_#{arr[4]}"
                    end

                    # overrides
                    if filename == "ortho_IL_15_655A1296005XJ_1_20240320"
                        original_poly_id = "655A1296005XJ_1"
                        final_poly_id = "655A1296005XJ_1"
                    elsif filename == "ortho_IL_15_655A1296005XJ_2_20240329"
                        original_poly_id = "655A1296005XJ_2"
                        final_poly_id = "655A1296005XJ_2"
                    elsif filename == "ortho_IL_15_665A1295005RH_1_20240329"
                        original_poly_id = "665A1295005RH_1"
                        final_poly_id = "665A1295005RH_1"
                    elsif filename == "ortho_IL_15_665A1295005RH_2_20240319"
                        original_poly_id = "665A1295005RH_2"
                        final_poly_id = "665A1295005RH_2"
                    elsif filename == "ortho_MA_15_7313209800H0ZA0007_A_20241004"
                        original_poly_id = "7313209800H0ZA0007_A"
                        final_poly_id = "7313209800H0ZA0007_A"
                    elsif filename == "ortho_MA_15_7313209800H0ZA0007_B_20241005"
                        original_poly_id = "7313209800H0ZA0007_B"
                        final_poly_id = "7313209800H0ZA0007_B"
                    elsif filename == "ortho_ND_15_ND_08_WAHL_20240629"
                        original_poly_id = "ND_08_WAHL"
                        final_poly_id = "ND_08_WAHL"
                    end

                    tile = Tile.ortho_processed.find_by(poly_id: original_poly_id)

                    p "-------"
                    p filename
                    p original_poly_id
                    p final_poly_id
                    p "-------"

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

    private

    def self.build_gtf gtf_file, filename, utm, poly_id

        p " "
        p "Build GTF"
        p "--------------------"
        p gtf_file
        p filename
        p utm.to_s
        p poly_id

        # Get the text from the GTF File
        gtf_text = File.read(gtf_file)

        # Get the GT Citation Match and value to replace
        gt_citation_match = 'GTCitationGeoKey (Ascii,33): "PCS Name = NAD_1983_UTM_Zone_'+utm.to_s+'N"'
        gt_citation_replace = 'GTCitationGeoKey (Ascii,'+(filename.size + 1).to_s+'): "'+filename+'"'

        # Match based on Zones
        if utm == 10                                      
            pcs_citation_match = 'PCSCitationGeoKey (Ascii,443): "ESRI PE String = PROJCS["NAD_1983_UTM_Zone_10N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-123.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]"'
            pcs_citation_replace = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 10N"'
        elsif utm == 11                                      
            pcs_citation_match = 'PCSCitationGeoKey (Ascii,443): "ESRI PE String = PROJCS["NAD_1983_UTM_Zone_11N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-117.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]"'
            pcs_citation_replace = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 11N"'
        elsif utm == 12                                      
            pcs_citation_match = 'PCSCitationGeoKey (Ascii,443): "ESRI PE String = PROJCS["NAD_1983_UTM_Zone_12N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-111.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]"'
            pcs_citation_replace = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 12N"'
        elsif utm == 13                                      
            pcs_citation_match = 'PCSCitationGeoKey (Ascii,443): "ESRI PE String = PROJCS["NAD_1983_UTM_Zone_13N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-105.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]"'
            pcs_citation_replace = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 13N"'
        elsif utm == 14
            pcs_citation_match = 'PCSCitationGeoKey (Ascii,442): "ESRI PE String = PROJCS["NAD_1983_UTM_Zone_14N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-99.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]"'
            pcs_citation_replace = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 14N"'
        elsif utm == 15
            pcs_citation_match = 'PCSCitationGeoKey (Ascii,442): "ESRI PE String = PROJCS["NAD_1983_UTM_Zone_15N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-93.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]"'
            pcs_citation_replace = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 15N"'
        elsif utm == 16
            pcs_citation_match = 'PCSCitationGeoKey (Ascii,442): "ESRI PE String = PROJCS["NAD_1983_UTM_Zone_16N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-87.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]"'
            pcs_citation_replace = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 16N"'
        elsif utm == 17
            pcs_citation_match = 'PCSCitationGeoKey (Ascii,442): "ESRI PE String = PROJCS["NAD_1983_UTM_Zone_17N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-81.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]"'
            pcs_citation_replace = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 17N"'
        elsif utm == 18
            pcs_citation_match = 'PCSCitationGeoKey (Ascii,442): "ESRI PE String = PROJCS["NAD_1983_UTM_Zone_18N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-75.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]"'
            pcs_citation_replace = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 18N"'
        elsif utm == 19
            pcs_citation_match = 'PCSCitationGeoKey (Ascii,442): "ESRI PE String = PROJCS["NAD_1983_UTM_Zone_19N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-69.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]"'
            pcs_citation_replace = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 19N"'
        elsif utm == 20
            pcs_citation_match = 'PCSCitationGeoKey (Ascii,442): "ESRI PE String = PROJCS["NAD_1983_UTM_Zone_20N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-63.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]"'
            pcs_citation_replace = 'PCSCitationGeoKey (Ascii,21): "NAD83 / UTM zone 20N"'
        elsif utm == 4
            pcs_citation_match = 'PCSCitationGeoKey (Ascii,442): "ESRI PE String = PROJCS["NAD_1983_UTM_Zone_4N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-159.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]"'
            pcs_citation_replace = 'PCSCitationGeoKey (Ascii,20): "NAD83 / UTM zone 4N"'
        elsif utm == 5
            pcs_citation_match = 'PCSCitationGeoKey (Ascii,442): "ESRI PE String = PROJCS["NAD_1983_UTM_Zone_5N",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137.0,298.257222101]],PRIMEM["Greenwich",0.0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000.0],PARAMETER["False_Northing",0.0],PARAMETER["Central_Meridian",-153.0],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0.0],UNIT["Meter",1.0]]"'
            pcs_citation_replace = 'PCSCitationGeoKey (Ascii,20): "NAD83 / UTM zone 5N"'
        else
            raise Exception, "#{filename}: UTM Zone #{utm} does not have a valid PSCitationGeoKey replacement value!"
        end

        # Check if the pcs_citation_match was ever set
        if pcs_citation_match.nil? 
            raise Exception, "#{filename}: PCSCitationGeoKey were not set for UTM Zone #{utm.to_s}N!"
        end

        # Check if the gt_citation_match is within the gtf file
        if !gtf_text.include? gt_citation_match
            raise Exception, "#{filename}: GTCitationGeoKey (#{gt_citation_match}) does not match GTF (#{gtf_file})!"
        end

        # Check if the pcs_citation_match is within the gtf file
        if !gtf_text.include? pcs_citation_match
            raise Exception, "#{filename}: PCSCitationGeoKey (#{pcs_citation_match}) does not match GTF (#{gtf_file})!"
        end

        # Update the text of the GTF file
        gtf_text = gtf_text.gsub(gt_citation_match, gt_citation_replace)
        gtf_text = gtf_text.gsub(pcs_citation_match, pcs_citation_replace)

        # Write the metadata back to the file
        File.open(gtf_file, "w") {|file| file.puts gtf_text }

    end

end