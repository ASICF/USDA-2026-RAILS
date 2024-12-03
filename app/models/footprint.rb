class Footprint < ApplicationRecord
    include Concerns::Archive

    # Associations
    belongs_to :upload
    belongs_to :plane
    belongs_to :camera
    belongs_to :vector_metadatum, optional: true
    belongs_to :county, optional: true
    belongs_to :state, optional: true
    belongs_to :project_state, class_name: 'State', optional: true
    belongs_to :utm, optional: true
    belongs_to :flown_by, class_name: 'Company', optional: true
    has_one :frame_center
    has_one :photo_index
    has_many :imagery_paths, as: :pathable
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs
    has_many :tile_footprints, dependent: :delete_all
    has_many :tiles, -> { distinct }, through: :tile_footprints
    has_many :doqq_footprints
    has_many :doqqs, -> { distinct }, through: :doqq_footprints

    # Validations
    validates :strip_frame, uniqueness: { scope: [:flight_date, :camera_id, :flown_by_id, :project, :project_state_name], message: "(%{value}) found with the same Flight Date, Flown By Company, and Camera already existing in Database" }
    validates :strip_frame, uniqueness: { scope: [:centroid_latitude, :centroid_longitude, :project, :project_state_name], message: "(%{value}) and centroid geometry found in Database for Footprints. Likely Duplicate." }, on: :create
    validates :geom, :flight_date, :centroid_latitude, :centroid_longitude, presence: true

    # Callbacks
    before_save :set_pilot_and_so

    def set_pilot_and_so
        self.pilot_name = "NA" if self.pilot_name.nil?
        self.camera_operator_name = "NA" if self.camera_operator_name.nil?
    end

    # Scopes
    scope :associated, -> { where(associated: true) }
    scope :not_associated, -> { where(associated: false) }
    scope :exclude_geom, -> { select( Footprint.attribute_names - ['geom'] ) }
    scope :sl, -> { where(sl: true) }
    scope :nri, -> { where(nri: true) }
    scope :naip, -> { where(naip: true) }
    scope :nri_sl, -> { where(sl: true, nri: true) }
    scope :not_uploaded, -> { where(provisional_upload_date: nil) }
    scope :uploaded, -> { where.not(provisional_upload_date: nil) }
    scope :has_flight_date_time, -> { where.not(flight_date_time: nil) }
    scope :needs_flight_date_time, -> { where(flight_date_time: nil) }
    scope :has_pi, -> { where(has_pi: true) }
    scope :needs_pi, -> { where(has_pi: false) }

    def self.prepare_import params, user

        response = {
            pass: false,
            message: nil
        }

        # Get the shapefile filename
        shapefile_filename = nil
        path = nil

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Verify the project is valid
                # if (!Rails.application.secrets.active_projects.include? params[:project])
                if (!["NRI/SL"].include? params[:project])
                    raise Exception, "Invalid Project (#{params[:project]}), must be #{Rails.application.secrets.active_projects.join(", ")}"
                end

                # Check 
                if (params[:project] == "NAIP" && params[:state_id].blank?)
                    raise Exception, "NAIP Projects require State included in the form"
                end

                # Get the folder name by converting the current time to seconds
                folder = Time.now.to_i

                path = "#{Rails.root}/assets/footprints/#{folder}"

                # Create a folder if it doesn't exist
                FileUtils.mkdir_p("#{path}/projected") unless File.directory?(path)
                FileUtils.mkdir("#{path}/original")

                # Used to make sure the required files are found
                shp = false
                shx = false
                dbf = false
                prj = false

                # Iterate the files and check if they are required and move them to the folder on the system
                params[:files].each do |file|

                    if File.extname(file.original_filename) == ".shp"
                        if shp
                            raise Exception, "Multiple .shp files found!"
                        else
                            shp = true
                            shapefile_filename = File.basename(file.original_filename, '.shp') 
                        end
                    elsif File.extname(file.original_filename) == ".shx"
                        if shx
                            raise Exception, "Multiple .shx files found!"
                        else
                            shx = true
                        end
                    elsif File.extname(file.original_filename) == ".dbf"
                        if dbf
                            raise Exception, "Multiple .dbf files found!"
                        else
                            dbf = true
                        end
                    elsif File.extname(file.original_filename) == ".prj"
                        if prj
                            raise Exception, "Multiple .prj files found!"
                        else
                            prj = true
                        end
                    end

                    @incoming_file = params[:file]
                    FileUtils.mv file.tempfile, "#{path}/original/#{file.original_filename}"
                end

                # If any of the variables are not true then abort
                if !shp || !shx || !dbf || !prj
                    raise Exception, "Missing .shp, .shx, .dbf, or .prj from upload!"
                else
                    response = {
                        pass: true,
                        message: "Form Data and Shapefile has been uploaded to the server and validated. Import process has been added to Job Queue. You will receive a message when it is completed."
                    }

                    # Split filename into an array
                    arr = shapefile_filename.split("_")

                    # # Validate the filename
                    # p "-----------------"
                    # p shapefile_filename
                    # p "Flight Date: #{arr[0]}"
                    # # p "State Abv: #{arr[1]}"
                    # p "Flown By: #{arr[1]}"
                    # p "Plane: #{arr[2]}"
                    # p "Camera: #{arr[3]}"
                    # p "-----------------"

                    # Check the Flight Dates
                    file_date = Date.parse(arr[0])
                    if file_date != Date.parse(params[:flight_date])
                        raise Exception, "Filename Flight Date does not match the Form supplied Flight Date"
                    end

                    # Check the Flown By Company
                    company = Company.find(params[:flown_by_id])
                    company_filename = Company.find_by(alias: arr[1])
                    if company.id != company_filename.id
                        raise Exception, "Company extract from Filename does not match the Company supplied by the form"
                    end

                    # Check the plane
                    plane = Plane.find_by(id: params[:plane_id])
                    plane_filename = Plane.find_by(name: arr[2])
                    if plane.id != plane_filename.id
                        raise Exception, "Plane extract from Filename does not match the Plane supplied by the form"
                    end

                    # Check if the plane is valid for the project
                    if params[:project] === "NAIP" && !plane.naip
                        raise Exception, "Plane is not approved for NAIP Project"
                    end
                    if params[:project] === "SL" && !plane.sl
                        raise Exception, "Plane is not approved for SL Project"
                    end

                    # Check the Camera
                    camera = Camera.find_by(id: params[:camera_id])
                    camera_filename = Camera.find_by(name: arr[3])
                    if camera.id != camera_filename.id
                        raise Exception, "Camera extract from Filename does not match the Camera supplied by the form"
                    end

                    # Check if the camera is valid for the project
                    # if (["All", "NAIP"].include? params[:project]) && !camera.naip
                    if params[:project] === "NAIP" && !camera.naip
                        raise Exception, "Camera is not approved for NAIP Project"
                    end
                    # if (["All", "SL"].include? params[:project]) && !camera.sl
                    if params[:project] === "SL" && !camera.sl
                        raise Exception, "Camera is not approved for SL Project"
                    end

                    # Call ogr2ogr to reproject the shapefile to 4326
                    # => Footprints should be in 4326, might be overkill but don't want to have to add later
                    `ogr2ogr -f "ESRI Shapefile" -t_srs EPSG:4326 #{path}/projected/footprints.shp "#{path}/original/#{shapefile_filename}.shp" -dim 2`

                    strip_frames = []
                    dup_strip_frames = []

                    # Iterate the shapefile and check for duplicates
                    RGeo::Shapefile::Reader.open("#{path}/projected/footprints.shp") do |file|
                        # puts "File contains #{file.num_records} records."
                        # p file
                        # p "--------------------"
                        file.each do |record|

                            # default the original strip frame variable to nil
                            original_strip_frame = nil

                            # Check the attributes for the Name field either proper case or capitialized
                            if record.attributes["Name"]
                                original_strip_frame = record.attributes["Name"]
                            elsif record.attributes["NAME"]
                                original_strip_frame = record.attributes["NAME"]
                            else
                                raise Exception, "No \"Name\" Column found for Strip Frame"
                            end
                        
                            puts "Record number #{original_strip_frame}:"

                            if strip_frames.include? original_strip_frame
                                dup_strip_frames |= [original_strip_frame]
                            else
                                strip_frames << original_strip_frame
                            end

                        end

                    end

                    # if there are dups then send an email
                    if dup_strip_frames.count > 0
                        
                        response = {
                            pass: false,
                            message: "Duplicates were found in the Footprint Import validation process. Please check your email to see a list of Strip Frames to resolve and try again."
                        }

                        html = "Duplicates found while validating the Footprint Import. Review and remove the following strip frames."
                        html += "<hr />"
                        html += '<ul>'
                        dup_strip_frames.each do |sf|
                            html += "<li>#{sf}</li>"
                        end
                        html += '</ul>'

                        # Log and send email
                        Mailbox.ship({
                            users: MailGroup.find_by(name: "Footprints").users | [user],
                            subject: "#{params[:project]} Footprint Import Duplicates Found",
                            message: html
                        })
                    end
                end


            rescue Exception => exception
                Rails.logger.error "Footprint Import Prep Error: #{exception.message}"
                p "-----------"
                p exception.backtrace.count
                exception.backtrace.each do |x|
                    next if !x.include? "footprint.rb"
                    x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
                   p [$1,$2,$4]
                end
                p "-----------"

                response[:pass] = false
                response[:message] = exception.message

                # Delete the files
                FileUtils.rm_rf("#{path}/") if path

                raise ActiveRecord::Rollback
            end
        end

        if response[:pass]
            Footprint.delay.import params, shapefile_filename, path, user
        end

        response

    end

    # Imports the shapefile
    def self.import params, shapefile_filename, path, user

        count = 0

        # Query out the Delayed Job
        # => Should be the first Delayed Job that is active that isnt' already assigned to an existing Job
        # delayed_job = Delayed::Job.where(attempts: 0, failed_at:nil).where.not(id: Job.all.pluck(:delayed_job_id).uniq).order(:id)

        job = Job.create(
            started_at: Time.now,
            active: true,
            message: "Processing Import...",
            process_type: "Footprint Import",
            filename: "#{shapefile_filename}.shp",
            creator: user,
            # delayed_job_id: delayed_job.count > 0 ? delayed_job.first.id : nil
        )

        project = params[:project]

        # Stores variables for the job process
        process_success = false
        error_message = "Something went wrong. Contact Programming"

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                upload = Upload.create(
                    folder_path: "#{path}/",
                    upload_type: "Footprint",
                    uploader: user
                )

                shp = Dir.glob("#{path}/projected/footprints.shp")

                if shp.empty?
                    raise Exception, "Could not find shapefile to upload"
                end

                # state = State.find(params[:state_id])
                plane = Plane.find(params[:plane_id])
                camera = Camera.find(params[:camera_id])
                company = Company.find(params[:flown_by_id])

                flight_date = Date.parse(params[:flight_date])

                # generate the provisional due date
                provisional_due_date = 5.business_days.after(flight_date)

                # Calculate the business days
                vm_array = []

                # Get the state, if no state then it should be nil
                state = nil
                if project == "NAIP"
                    state = State.find_by(id: params[:state_id])
                end

                # Call ogr2ogr to reproject the shapefile to 4326
                # => Footprints should be in 4326, might be overkill but don't want to have to add later
                # `ogr2ogr -f "ESRI Shapefile" -t_srs EPSG:4326 #{path}/projected/footprints.shp #{shp.first} -dim 2`

                RGeo::Shapefile::Reader.open("#{path}/projected/footprints.shp") do |file|
                    # puts "File contains #{file.num_records} records."
                    # p file
                    # p "--------------------"
                    file.each do |record|

                        # default the original strip frame variable to nil
                        original_strip_frame = nil

                        # Check the attributes for the Name field either proper case or capitialized
                        if record.attributes["Name"]
                            original_strip_frame = record.attributes["Name"]
                        elsif record.attributes["NAME"]
                            original_strip_frame = record.attributes["NAME"]
                        else
                            raise Exception, "No \"Name\" Column found for Strip Frame"
                        end
                    
                        puts "Record number #{original_strip_frame}:"

                        # Split the strip frame
                        arr = original_strip_frame.split("-")

                        # check the Name field to see if it needs to be modified
                        if arr.count == 1
                            arr = original_strip_frame.split("_")

                            # If it's valid it should be similar to "1234_7890"
                            if arr.count == 2 && arr[0].size == 4 && arr[1].size == 4 
                                modified_strip_frame = original_strip_frame
                            else
                                raise Exception, "Invalid Strip Frame: #{original_strip_frame}"
                            end
                        else
                            # strip frame segment might not include the third portion (segment)
                            if arr.count < 2 || arr.count > 3
                                raise Exception, "Invalid Strip Frame: #{original_strip_frame}"
                            end

                            if arr.count == 3
                                # Remove the last array (segment)
                                arr.pop
                            end

                            if arr[0].length < 4
                                # Buffer the second array with "0" to be 4 digits
                                arr[0] = "#{"0" * (4 - arr[0].length)}#{arr[0]}"
                            end

                            # if the frame is greater than 5 digits then return the last 4 digits off 
                            if arr[1].length > 4
                                arr[1] = arr[1][-4..-1]
                            end

                            # Buffer the second array with "0" to be 4 digits
                            if arr[1].length < 4 
                                arr[1] = "#{"0" * (4 - arr[1].length)}#{arr[1]}"
                            end

                            # Join with an underscore
                            modified_strip_frame = arr.join("_")
                        end

                        # p modified_strip_frame


                        if project === "NAIP"
                            # Check if the strip frame has already been used with the same flight date
                            if Footprint.naip.where(strip_frame: modified_strip_frame, flight_date: params[:flight_date], camera_id: camera.id, flown_by_id: company.id, project_state_name: state.name).count > 0
                                raise Exception, "Strip Frame (Original: #{original_strip_frame}, Modified: #{modified_strip_frame}) already exists with the same Flight Date (#{params[:flight_date]}), Camera (#{camera.serial_number}), and Flown By Company (#{company.name}) for NAIP Project within #{state.name}"
                            end
                        else
                            # Check if the strip frame has already been used with the same flight date
                            if Footprint.nri_sl.where(strip_frame: modified_strip_frame, flight_date: params[:flight_date], camera_id: camera.id, flown_by_id: company.id).count > 0
                                raise Exception, "Strip Frame (Original: #{original_strip_frame}, Modified: #{modified_strip_frame}) already exists with the same Flight Date (#{params[:flight_date]}), Camera (#{camera.serial_number}), and Flown By Company (#{company.name})"
                            end
                        end

                        footprint = Footprint.new(
                            project: project,
                            original_strip_frame: original_strip_frame,
                            strip_frame: modified_strip_frame,
                            flight_date: params[:flight_date],
                            geom: record.geometry,
                            pilot_name: params[:pilot_name].blank? ? nil : params[:pilot_name],
                            camera_operator_name: params[:camera_operator_name].blank? ? nil : params[:camera_operator_name],
                            plane: plane,
                            camera: camera,
                            upload: upload,
                            nri: false,
                            sl: false,
                            naip: project == "NAIP" ? true : false,
                            flown_by_alias: company.alias,
                            flown_by_name: company.name,
                            flown_by_id: company.id,
                            plane_name: plane.name,
                            camera_name: "#{camera.model} | #{camera.name}",
                        )

                        # Add the centroid lat/long
                        footprint.centroid_latitude = footprint.geom.centroid.y
                        footprint.centroid_longitude = footprint.geom.centroid.x

                        # Get the footprint UTM zone
                        sql = "select id, zone from utms u where st_intersects(ST_GeomFromText('#{footprint.geom.to_s}'), u.geom) 
                            and (st_area(st_intersection(ST_GeomFromText('#{footprint.geom.to_s}'), u.geom))/st_area(ST_GeomFromText('#{footprint.geom.to_s}'))) > .5"
                        result = ActiveRecord::Base.connection.execute(sql)

                        footprint.utm_id = result[0]["id"]
                        footprint.utm_zone = "#{result[0]["zone"]}N"

                        # Get the footprint County
                        # Skip if Doqq

                        # get the states by project
                        # if project == "SL"
                        #     abvs = Rails.application.secrets.active_sl_states
                        # elsif project == "NRI"
                        #     abvs = Rails.application.secrets.active_nri_states
                        # elsif project == "NAIP"
                        #     abvs = Rails.application.secrets.active_naip_states
                        # end

                        # Query out the county the most majority is in and also include the state info
                        # sql = "select c.id as county_id, c.name as county_name, s.id as state_id, s.abv as state_abv, s.name as state_name from counties c INNER JOIN states s ON c.state_id = s.id
                        #     where st_intersects(ST_GeomFromText('#{footprint.geom.to_s}'), c.geom) and s.abv in ('#{abvs.join("', '")}') 
                        #     order by (st_area(st_intersection(ST_GeomFromText('#{footprint.geom.to_s}'), c.geom))/st_area(ST_GeomFromText('#{footprint.geom.to_s}'))) DESC"

                        sql = "select c.id as county_id, c.name as county_name, s.id as state_id, s.abv as state_abv, s.name as state_name from counties c INNER JOIN states s ON c.state_id = s.id
                            where st_intersects(ST_GeomFromText('#{footprint.geom.to_s}'), c.geom) 
                            order by (st_area(st_intersection(ST_GeomFromText('#{footprint.geom.to_s}'), c.geom))/st_area(ST_GeomFromText('#{footprint.geom.to_s}'))) DESC"
                        
                        results = ActiveRecord::Base.connection.execute(sql)

                        if results.count > 0
                            # update the county info
                            footprint.county_id = results[0]["county_id"]
                            footprint.county_name = results[0]["county_name"]
                            # update the state info
                            footprint.state_id = results[0]["state_id"]
                            footprint.state_name = results[0]["state_name"]
                            footprint.state_abv = results[0]["state_abv"]
                        end

                        if project == "NAIP"
                            footprint.project_state_name = state.name
                            footprint.project_state_id = state.id
                        end

                        # if project == "NAIP"

                        #     # Find the associated vector metadatum
                        #     vm = VectorMetadatum.find_or_create_by(
                        #         project: "NAIP", 
                        #         flight_date: params[:flight_date],
                        #         service_name: "#{state.abv}_PROVISIONAL_4B_#{flight_date.strftime("%Y%m%d")}",
                        #         state_name: state.name,
                        #         provisional_due_date: provisional_due_date,
                        #         state_id: state.id
                        #     )

                        #     # Add the footprints to the vm
                        #     vm.footprints << footprint

                        #     # add the vm to the vm array
                        #     vm_array |= [vm]

                        # end

                        if !footprint.save
                            raise Exception, footprint.errors.full_messages.to_sentence
                        end

                        count += 1
                    end
                end

                # Create a new History record
                history = History.new
                history.action_type = "Upload Footprints (#{project})"
                history.creator = user
                history.message = "Uploaded #{count} Footprints in #{upload.footprints.order(:state_name).pluck(:state_name).uniq.to_sentence} from #{shapefile_filename}.shp"
                history.save

                upload.number_uploaded = count
                upload.save

                p "Project: #{project}"

                # Compare the Project Type and perform Spatial Query
                # if ["All", "Sl"].include? project
                if project == "NRI/SL"

                    # Dissolve all the footprints in the db
                    # => Now it should only dissolve those that have the correct flight date
                    DissolvedFootprint.dissolve_by_scope params[:flight_date], company.id, camera.id, project

                    # Find new completed Easements and update their flight date
                    Footprint.update_tiles upload, history, params[:flight_date], plane, camera, company, params[:pilot_name], params[:camera_operator_name], project

                    # CHeck if any of the footprints cover already flown easements
                    Footprint.delay.find_duplicate_overlapping_footprints_for_tiles upload, project, user
                end

                # # if ["All", "NAIP"].include? project
                # if project == "NAIP"

                #     # Parse the flight date so it 
                #     # parsed_flight_date = Date.parse(flight_date)

                #     # generate the provisional due date
                #     provisional_due_date = 5.business_days.after(flight_date)

                #     # Find the associated vector metadatum
                #     vm = VectorMetadatum.find_or_create_by(
                #         project: "NAIP", 
                #         flight_date: flight_date,
                #         service_name: "#{state.abv}_PROVISIONAL_4B_#{flight_date.strftime("%Y%m%d")}",
                #         state_name: state.name,
                #         provisional_due_date: provisional_due_date,
                #         state_id: state.id
                #     )

                #     p upload.footprints.count
                #     # vm.footprints << upload.footprints
                #     upload.footprints.update_all(vector_metadatum_id: vm.id)

                #     # Dissolve all the footprints in the db
                #     # => Now it should only dissolve those that have the correct flight date
                #     DissolvedFootprint.dissolve_by_flight_date_and_project_state params[:flight_date], state.id, project

                #     # Find new completed DOQQs and update their flight date
                #     # history = Footprint.update_doqqs upload, history, params[:flight_date], state, project
                #     history = Footprint.update_doqqs upload, history, project, vm
                # end

                # Update the Filenames of Flown Footprints
                # Tile.update_filename

                p "DONE WITH PROJECT SPECIFIC OPERATIONS"

                if count > 0

                    # add records to polymorphic association
                    history.uploads << upload
                    history.footprints = upload.footprints

                elsif output[:count] == 0
                    raise Exception, "No Footprint Features were uploaded, please check the shapefile for a valid projection and try again."
                else
                    raise Exception, "Something went wrong"
                end

                job.update(
                    finished_at: Time.now,
                    success: true,
                    active: false,
                    upload: upload,
                    message: "Uploaded #{count} Footprints"
                )

                # Log and send email
                Mailbox.ship({
                    users: MailGroup.find_by(name: "Footprints").users | [user],
                    subject: "#{project} Footprint Import Success",
                    message: "#{project} Footprint Import finished successfully, #{upload.footprints.count} Footprints were uploaded to the application."
                })

                # PostmasterMailer.notify(user, "Footprint Import finished successfully, #{upload.footprints.count} Footprints were uploaded to the system.", "USDA #{Rails.application.secrets.project_year}: Footprint Import Success - #{Time.now.strftime("%m/%d/%Y")}").deliver

                # p "Last file email: #{params[:last_file]}"
                # if params[:last_file].to_i == 1
                #     Rails.application.secrets.last_file_users.each do |lf_user|
                #         next if User.find_by(lf_user).nil?
                #         PostmasterMailer.notify(User.find_by(lf_user), "#{user.full_name} has uploaded the last footprint for #{params[:flight_date].to_date.strftime("%A, %m/%d/%Y")}.", "USDA #{Rails.application.secrets.project_year}: Last Footprint Uploaded for the Day - #{Time.now.strftime("%m/%d/%Y")}").deliver
                #     end
                # end

                # Update the process
                process_success = true

            rescue Exception => exception
                Rails.logger.error "Footprint Import Error: #{exception.message} | #{shapefile_filename}.shp"
                p "-----------"
                p exception.backtrace.count
                exception.backtrace.each do |x|
                    next if !x.include? "footprint.rb"
                    x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
                   p [$1,$2,$4]
                end
                p "-----------"

                error_message = exception.message

                # Delete the Upload and History
                upload.destroy if upload
                history.destroy if history

                # Delete the files
                FileUtils.rm_rf("#{path}/") if path

                # Update the process 
                process_success = false

                raise ActiveRecord::Rollback
            end
        end

        # Run if the process failed
        if !process_success

            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Footprints").users | [user],
                subject: "#{project} Footprint Import Failed",
                message: "#{project} Footprint Import Failed, Error caught during import process for #{shapefile_filename}.shp.<br/><br/>#{error_message}".html_safe
            })

            # # Send email to notified it failed
            # PostmasterMailer.notify(user, "Footprint Import Failed, Error caught during import process for #{shapefile_filename}.shp.<br/><br/>#{error_message}".html_safe, "USDA #{Rails.application.secrets.project_year}: Footprint Import Failed - #{Time.now.strftime("%m/%d/%Y")}").deliver

            # Update the Job
            job.update(
                finished_at: Time.now,
                active: false,
                success: false,
                message: "Import Failed",
                upload: nil,
                error_message:  error_message
            )

        end

    end

    def self.eo_shapefile_export upload, footprints, user

        # set the path variable in case of failure
        path = nil

        begin

            # Get the folder name by converting the current time to seconds
            folder = Time.now.to_i

            path = "#{Rails.root}/assets/eo_tracker/#{folder}"

            # Create a folder if it doesn't exist
            FileUtils.mkdir_p("#{path}") unless File.directory?(path)
            FileUtils.mkdir_p("#{path}/json")
            FileUtils.mkdir_p("#{path}/shapefile")
            FileUtils.mkdir_p("#{path}/zipped")

            # Set the formated date to a string to be reused
            time_string = Time.now.strftime("%y%m%d")

            # shapefiles = []

            factory = RGeo::GeoJSON::EntityFactory.instance

            # Set the file name
            file_name = "eo_tracker_footprints_that_need_eos_upload_id_#{upload.id}"

            features = Array.new

            # Get State
            footprints.each do |record|

                obj = {
                    StripFrame: record.strip_frame,
                    FlightDate: record.flight_date.strftime("%F"),
                    Plane: record.plane_name,
                    Camera: record.camera_name,
                    FlownBy: record.flown_by_alias,
                    State: record.state_name,
                    County: record.county_name,
                    GPSTime: record.photo_index.present? ? record.photo_index.gpstime : 'NA',
                    UTM: record.utm_zone,
                }

                features << factory.feature(record.geom, record.id, obj)

            end

            # Creates a text file and saves it to the report directory
            File.open("#{path}/json/#{file_name}.json", "w+") do |f|
                f.puts(RGeo::GeoJSON.encode(factory.feature_collection(features)).to_json)
            end

            # Convert GeoJSON to Shapefile with ogr2ogr
            `ogr2ogr -f "ESRI Shapefile" -fieldTypeToString Date,Time #{path}/shapefile/#{file_name}.shp "#{path}/json/#{file_name}.json"`

            # shapefiles << file_name

            # Zip the files
            Zip::File.open("#{path}/zipped/#{file_name}.zip", Zip::File::CREATE) do |zipfile|
                [".shp", ".shx", ".dbf", ".prj"].each do |ext|
                    zipfile.add("#{file_name}#{ext}", File.join("#{path}/shapefile/", "#{file_name}#{ext}"))
                end
            end

            # Create a new History record
            history = History.new
            history.message = "Generated Shapefile of #{footprints.count} that need Frame Centers for Upload: #{upload.id}"
            history.action_type = "EO Tracker Shapefile Export"
            history.url = "#{path}/zipped/#{file_name}.zip"
            history.creator = user
            history.save

            return {
                state: true,
                history_id: history.id
            }
          
        rescue StandardError => e
            FileUtils.rm_rf(path) if File.directory?(path)
            return {
                state: false,
                message: "Error: #{e.message}"
            }

        end

    end


    def self.pi_shapefile_export upload, footprints, user

        # set the path variable in case of failure
        path = nil

        begin

            # Get the folder name by converting the current time to seconds
            folder = Time.now.to_i

            path = "#{Rails.root}/assets/pi_tracker/#{folder}"

            # Create a folder if it doesn't exist
            FileUtils.mkdir_p("#{path}") unless File.directory?(path)
            FileUtils.mkdir_p("#{path}/json")
            FileUtils.mkdir_p("#{path}/shapefile")
            FileUtils.mkdir_p("#{path}/zipped")

            # Set the formated date to a string to be reused
            time_string = Time.now.strftime("%y%m%d")

            # shapefiles = []

            factory = RGeo::GeoJSON::EntityFactory.instance

            # Set the file name
            file_name = "photo_index_tracker_footprints_that_need_photo_indices_upload_id_#{upload.id}"

            features = Array.new

            # Get State
            footprints.each do |record|

                obj = {
                    StripFrame: record.strip_frame,
                    FlightDate: record.flight_date.strftime("%F"),
                    Plane: record.plane_name,
                    Camera: record.camera_name,
                    FlownBy: record.flown_by_alias,
                    State: record.state_name,
                    County: record.county_name,
                    UTM: record.utm_zone,
                }

                features << factory.feature(record.geom, record.id, obj)

            end

            # Creates a text file and saves it to the report directory
            File.open("#{path}/json/#{file_name}.json", "w+") do |f|
                f.puts(RGeo::GeoJSON.encode(factory.feature_collection(features)).to_json)
            end

            # Convert GeoJSON to Shapefile with ogr2ogr
            `ogr2ogr -f "ESRI Shapefile" -fieldTypeToString Date,Time #{path}/shapefile/#{file_name}.shp "#{path}/json/#{file_name}.json"`

            # shapefiles << file_name

            # Zip the files
            Zip::File.open("#{path}/zipped/#{file_name}.zip", Zip::File::CREATE) do |zipfile|
                [".shp", ".shx", ".dbf", ".prj"].each do |ext|
                    zipfile.add("#{file_name}#{ext}", File.join("#{path}/shapefile/", "#{file_name}#{ext}"))
                end
            end

            # Create a new History record
            history = History.new
            history.message = "Generated Shapefile of #{footprints.count} that need Photo Indices for Upload: #{upload.id}"
            history.action_type = "Photo Index Tracker Shapefile Export"
            history.url = "#{path}/zipped/#{file_name}.zip"
            history.creator = user
            history.save

            return {
                state: true,
                history_id: history.id
            }
          
        rescue StandardError => e
            FileUtils.rm_rf(path) if File.directory?(path)
            return {
                state: false,
                message: "Error: #{e.message}"
            }

        end

    end

    def self.fix_project_assoc
        # iterates the footprints that do not have 
        Footprint.where(nri: false, sl: false, associated: true).each do |fp|
            # check the associated tile's project
            nri = false;
            sl = false;

            # iterate and check the 
            fp.tiles.each do |tile|
                if tile.project === "SL"
                    sl = true;
                end
                if tile.project === "NRI"
                    nri = true;
                end
            end

            # update footprint
            fp.update(nri: nri, sl: sl)

            # update frame center
            fp.frame_center.update(nri: nri, sl: sl)
        end
    end

    private

    # Should only run after the dissolved footprint has been built
    def self.update_tiles upload, history, flight_date, plane, camera, company, pilot, so, project

        tiles = []
        footprints = []

        # Parse the flight date so it 
        parsed_flight_date = Date.parse(flight_date)

        # generate the provisional due date
        provisional_due_date = 5.business_days.after(parsed_flight_date)

        # associated_footprints = []
        invalid_contract_rates = []

        # track which projects are affected
        nri = false
        sl = false

        if !flight_date.nil?

            # Returns all easements that do not have a Flight date that fall within the dissolved footprints
            # => Update the Flight Date on the Easements and add info to it's Tiles.
            Easement.not_flown.joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='scoped' AND st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").each do |easement|
                easement.update(flight_date: flight_date)
                easement.tiles.not_flown.each do |tile|

                    # # Find the associated vector metadatum
                    # vm = VectorMetadatum.find_or_create_by(
                    #     project: project, 
                    #     flight_date: flight_date,
                    #     service_name: "#{tile.state.abv}_PROVISIONAL_4B_#{parsed_flight_date.strftime("%Y%m%d")}",
                    #     state_name: tile.state.abv,
                    #     provisional_due_date: provisional_due_date,
                    #     state_id: tile.state_id
                    # )

                    # Update each tile and reset the asi_rejected_date back to nil
                    tile.update(
                        flight_date: flight_date,
                        asi_rejected_date: nil,
                        filename: tile.build_filename,
                        camera_name: "#{camera.model} | #{camera.name}",
                        camera: camera,
                        plane_name: plane.name,
                        plane: plane,
                        flown_by_alias: company.alias,
                        flown_by_name: company.name,
                        flown_by: company,
                        pilot: pilot,
                        sensor_operator: so
                    )

                    # Update the Tiles Rate and if it's not successful then push to array to send email later
                    if !tile.set_contract_rate
                        invalid_contract_rates << tile
                    end

                    # Add tile to history
                    history.tiles << tile

                    # # Query against the Footprint geometry scoped based on the previous footprint id array
                    # sql = "SELECT fp.id as footprint_id from easements e, footprints fp where st_intersects(e.geom, fp.geom) 
                    #       AND e.id = #{easement.id} AND fp.camera_id=#{camera.id} AND fp.flown_by_id=#{company.id} 
                    #       AND fp.plane_id=#{plane.id} AND fp.project='#{project}' AND fp.flight_date = '#{parsed_flight_date.strftime("%F")}'"
                    # results = ActiveRecord::Base.connection.execute(sql)

                    sql = "SELECT fp.id as footprint_id from tiles t, footprints fp where st_intersects(t.geom, fp.geom) 
                          AND t.id = #{tile.id} AND fp.camera_id=#{camera.id} AND fp.flown_by_id=#{company.id} 
                          AND fp.plane_id=#{plane.id} AND fp.project='#{project}' AND fp.flight_date = '#{parsed_flight_date.strftime("%F")}'"
                    results = ActiveRecord::Base.connection.execute(sql)

                    # iterate the results
                    results.each do |record|

                        # Find the footprint
                        footprint = Footprint.find(record["footprint_id"])

                        # create a new hash to update the Footprint
                        obj = {
                            naip: false,
                            associated: true
                        }

                        # if the tile is NRI then set the footprint nri boolean to true
                        if tile.project == "NRI"
                            nri = true
                            obj[:nri] = true
                        end

                        # if the tile is SL then set the footprint sl boolean to true
                        if tile.project == "SL"
                            sl = true
                            obj[:sl] = true
                        end

                        # update the footprint
                        footprint.update(obj)

                        # Add the Footprint to the tiles and the vectormetadatum
                        tile.footprints << footprint
                        # tile.update(vector_metadatum_id: vm.id)

                        # associated_footprints |= [footprint]

                        # Associate the footprint to the vector metadataum
                        # vm.footprints << footprint

                        # Add footprint to history
                        footprints << footprint
                    end

                    tiles << tile
                end
            end

            # if associated_footprints.count > 0

            #     p "Destroying #{upload.footprints.where.not(id: associated_footprints).count} Footprints out of #{upload.footprints.count}"

            #     # Delete all the footprints that did not match
            #     upload.footprints.where.not(id: associated_footprints).destroy_all

            # end
        end

        # Mark joining tiles to footprints
        tile_footprint_history = History.new
        tile_footprint_history.action_type = "Join Footpint to Tile"
        tile_footprint_history.creator = history.creator
        tile_footprint_history.message = "Associated #{footprints.uniq.count} Footprints to #{tiles.count} Tiles"
        tile_footprint_history.save

        # Associate the Tiles and Footprints to the history record
        tile_footprint_history.tiles << tiles
        tile_footprint_history.footprints << footprints.uniq

        # check if the tiles were all successfully updated or not
        if invalid_contract_rates.size > 0

            html = "<p>The Following Tiles could not find valid Contract Rates during the Footprint Import.</p>"

            html += '<table width="100%" style="border: 1px solid black;">'\
                '<tr>'\
                    '<th align="center" style="border: 1px solid black;">Poly ID</th>'\
                    '<th align="center" style="border: 1px solid black;">Project</th>'\
                    '<th align="center" style="border: 1px solid black;">State</th>'\
                    '<th align="center" style="border: 1px solid black;">Flown By</th>'\
                    '<th align="center" style="border: 1px solid black;">Flight Date</th>'\
                '</tr>'

            invalid_contract_rates.each do |tile|

                html += '<tr>'\
                    "<td align='center' style='border: 1px solid black;'>#{tile.poly_id}</td>"\
                    "<td align='center' style='border: 1px solid black;'>#{tile.project_no}</td>"\
                    "<td align='center' style='border: 1px solid black;'>#{tile.state_name}</td>"\
                    "<td align='center' style='border: 1px solid black;'>#{tile.flown_by_name}</td>"\
                    "<td align='center' style='border: 1px solid black;'>#{tile.flight_date.strftime("%m/%d/%Y")}</td>"\
                '</tr>'
            end

            html += "</table>"


            # Create a list of the poly ids
            tile_list = invalid_contract_rates.map {|tile| "<li>#{tile.poly_id}: #{tile.state_name} - #{tile.flown_by_name} - #{tile.flight_date.strftime("%m/%d/%Y")}</li>"}.join("")

            # ship it
            Mailbox.ship({
                users: MailGroup.find_by(name: "Errors").users | [history.creator],
                subject: "Tiles with missing Contract Rates",
                message: html  
            })
        end

        # Check completed counties for nri and sl if affected
        if nri
            Tile.delay.check_fully_flown_counties "NRI"
        end

        if sl
            Tile.delay.check_fully_flown_counties "SL"
        end
    end

    # def self.update_doqqs upload, history
    # def self.update_doqqs upload, history, project, vm
    # def self.update_doqqs upload, history, params[:flight_date], state, project
    def self.update_doqqs upload, history, project, vm
        p "update_doqqs"

        # doqqs = []
        footprint_ids = []

        # associated_footprints = []

        # Query DOQQ that intersect the Dissolved Footprints scoped by flight date and the project state
        vm.state.doqqs.not_flown.joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='flight_date' AND st_intersects(dissolved_footprints.geom::geometry, doqqs.geom::geometry)").each do |doqq|

            # Add the doqq to the array
            # doqqs << doqq

            # Query against the Footprint geometry scoped based on the previous footprint id array
            # sql = "select footprints.id as footprint_id from doqqs, footprints where st_intersects(doqqs.geom, footprints.geom) AND doqqs.id = #{doqq.id} and footprints.project = 'NAIP'"
            sql = "select footprints.id as footprint_id from doqqs, footprints where st_intersects(doqqs.geom, footprints.geom) AND doqqs.id = #{doqq.id} and footprints.project = 'NAIP' and footprints.project_state_id = #{vm.state.id}"
            results = ActiveRecord::Base.connection.execute(sql)

            # iterate the results
            results.each do |record|

                footprint = Footprint.find_by(id: record["footprint_id"], project: project)

                # Add the Footprint to the tiles
                doqq.footprints << footprint

                # associated_footprints |= [footprint]

                # Add the footprint to the footprint array for later query
                # footprint_ids << footprint.id if !footprint_ids.include? footprint.id
                footprint_ids |= [footprint.id]
            end

        end

        p "+_+_+_+_+"
        p footprint_ids
        p "+_+_+_+_+"

        # Dissolve the footprints that were selected and check 
        if footprint_ids.count > 0
            # Dissolve all the associated Footprints of the DOQQ layer and check if it's completely overed or not
            DissolvedFootprint.footprints footprint_ids, project

            # Query the Doqq files that are completely contained by the selected footprints
            vm.state.doqqs.not_flown.joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='footprints' AND st_contains(dissolved_footprints.geom::geometry, doqqs.geom::geometry)").each do |doqq|

                # Update the majority flight date
                # doqq.generate_majority_flight_date
                doqq.update(vector_metadatum_id: vm.id, flight_date: vm.flight_date)

                # Build the filename
                # doqq.update(filename: doqq.build_filename)

                # Add the DOQQs to the History
                history.doqqs << doqq
            end

            # Cleanup, destory the dissolved_footprints
            DissolvedFootprint.destroy_footprints
        end


        # if associated_footprints.count > 0

        #     p "Destroying #{upload.footprints.where.not(id: associated_footprints).count} Footprints out of #{upload.footprints.count}"

        #     # Delete all the footprints that did not match
        #     upload.footprints.where.not(id: associated_footprints).destroy_all

        # end

        # Cleanup, destory the dissolved_footprints
        DissolvedFootprint.destroy_dissolve_by_flight_date

        # return the history
        history
    end

    # def self.test
    #     Upload.where(upload_type: "Footprint", created_at: Time.now.beginning_of_day...Time.now.end_of_day).each do |upload|
    #         Footprint.find_duplicate_overlapping_footprints_for_tiles upload
    #     end
    # end

    def self.find_duplicate_overlapping_footprints_for_tiles upload, project, user
        # Take the footprints that were just uploaded and dissolve them to check for coverage that is already marked as flown but not on the same flight date

        p "_+_+_+_+_+_"
        p "Upload #{upload.id}"

        # Create a new History record
        history = History.new
        history.action_type = "Duplicate Overlapping Footprints"
        history.creator = user
        history.save

        first = upload.footprints.first
        flight_date = first.flight_date.strftime("%F")

        # Dissolve all the footprints in the db
        # => Now it should only dissolve those that have the correct flight date
        DissolvedFootprint.dissolve_by_scope flight_date, first.flown_by_id, first.camera_id, project

        # Find all easements that are completely covered and marked as flown but not on the same flight date
        Easement.flown.nri_sl.where.not(flight_date: flight_date).joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='scoped' AND st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").each do |easement|

            # update the covered boolean on the Tile 
            easement.tiles.first.update(covered: true)

            # add the tiles to the history
            history.tiles << easement.tiles
        end

        if history.tiles.count > 0
            # update the message
            history.update(message: "Found overlapping footprints for #{history.tiles.count} Easements")

            # build a list of affected poly_ids
            tile_list = history.tiles.order(:poly_id).map {|tile| "<li>#{tile.poly_id}</li>"}.join("")

            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Easements with Multiple Coverages").users | [user],
                subject: "#{project} Easements with Multiple Coverages",
                message: "There are #{history.tiles.count} Easements were marked as covered by multiple Flight Dates. Please click link below to reivew and set the correct Footprint association. There will be a daily email sent until all coverages are updated.<hr/><ul>#{tile_list}</ul>".html_safe,
                route: Rails.application.routes.url_helpers.easements_with_multiple_coverages_url(only_path: false, host: Rails.application.secrets.host)    
            })

            # # send out email
            # Rails.application.secrets.multiple_covered_users.each do |user_obj|
            #     record = User.find_by(user_obj)
            #     next if record.nil?
            #     PostmasterMailer.notify(record, "There are #{history.tiles.count} Easements were marked as covered by multiple Flight Dates. Please click link below to reivew and set the correct Footprint association. There will be a daily email sent until all coverages are fixed.<hr/>#{tile_list}<ul></ul>".html_safe, "USDA #{Rails.application.secrets.project_year}: Duplicate Overlapping Footprints - #{Time.now.strftime("%m/%d/%Y")}", Rails.application.routes.url_helpers.easements_with_multiple_coverages_url(only_path: false, host: Rails.application.secrets.host)).deliver
            # end

        else
            # destroy the history object because there was no overlapping
            history.delete
        end

    end

    # def self.update_doqqs_old upload, history, flight_date, state, project
    #     p "update_doqqs"

    #     # Parse the flight date so it 
    #     parsed_flight_date = Date.parse(flight_date)

    #     p parsed_flight_date.strftime("%Y%m%d")

    #     # generate the provisional due date
    #     provisional_due_date = 5.business_days.after(parsed_flight_date)

    #     footprint_ids = []

    #     # Query DOQQ that intersect the Dissolved Footprints
    #     state.doqqs.not_flown.joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='flight_date' AND st_intersects(dissolved_footprints.geom::geometry, doqqs.geom::geometry)").each do |doqq|

    #         # Add the doqq to the array
    #         # doqqs << doqq

    #         # Query against the Footprint geometry scoped based on the previous footprint id array
    #         sql = "select footprints.id as footprint_id from doqqs, footprints where st_intersects(doqqs.geom, footprints.geom) AND doqqs.id = #{doqq.id} and footprints.project = 'NAIP' and footprints.project_state_id = #{state.id}"
    #         results = ActiveRecord::Base.connection.execute(sql)

    #         # iterate the results
    #         results.each do |record|

    #             footprint = Footprint.find_by(id: record["footprint_id"], project: project)

    #             # Add the Footprint to the tiles
    #             doqq.footprints << footprint

    #             # Add the footprint to the footprint array for later query
    #             # footprint_ids << footprint.id if !footprint_ids.include? footprint.id
    #             footprint_ids |= [footprint.id]
    #         end

    #     end

    #     p footprint_ids

    #     if footprint_ids.count > 0
    #         # Dissolve all the associated Footprints of the DOQQ layer and check if it's completely overed or not
    #         DissolvedFootprint.footprints footprint_ids, project

    #         # Query the Doqq files that are completely contained by the selected footprints
    #         state.doqqs.not_flown.joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='footprints' AND st_contains(dissolved_footprints.geom::geometry, doqqs.geom::geometry)").each do |doqq|

    #             p doqq.id

    #             # # Find the associated vector metadatum
    #             # vm = VectorMetadatum.find_or_create_by(
    #             #     project: "NAIP", 
    #             #     flight_date: flight_date,
    #             #     service_name: "#{state.abv}_PROVISIONAL_4B_#{parsed_flight_date.strftime("%Y%m%d")}",
    #             #     state_name: state.name,
    #             #     provisional_due_date: provisional_due_date,
    #             #     state_id: state.id
    #             # )

    #             # Update the majority flight date
    #             # doqq.generate_majority_flight_date
    #             doqq.update(vector_metadatum_id: vm.id, flight_date: vm.flight_date)

    #             # Assocaite the doqq footprints to the 
    #             vm.footprints << doqq.footprints.naip.where(flight_date: flight_date, project_state_id: state.id)

    #             # Add the DOQQs to the History
    #             history.doqqs << doqq
    #         end

    #         # Cleanup, destory the dissolved_footprints
    #         DissolvedFootprint.destroy_footprints
    #     end

    #     # Cleanup, destory the dissolved_footprints
    #     DissolvedFootprint.destroy_dissolve_by_flight_date

    #     # return the history
    #     history
    # end

    def self.fix_tiles_pilot_so

        # Create a new dissolved layer for specificallly here
        # Upload.where(upload_type: "Footprint").order(:created_at).each do |upload|
        Footprint.all.pluck(:pilot_name).uniq.each do |pilot|

            name = "fix_for_pilot_#{pilot}"

            # Create a new dissolved layer 
            DissolvedFootprint.find_by(name: name).destroy if DissolvedFootprint.find_by(name: name).present?
            DissolvedFootprint.create(name: name)

            # Add those footprints to the dissolved layer
            sql = "UPDATE dissolved_footprints SET geom = (SELECT st_union(geom::geometry) AS the_geom from footprints WHERE pilot_name='#{pilot}') WHERE name='#{name}'"
            results = ActiveRecord::Base.connection.execute(sql)

            Easement.flown.joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='#{name}' AND st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").each do |easement|
                easement.tiles.flown.where(pilot: nil).update(pilot: pilot)
            end

        end

        Footprint.all.pluck(:camera_operator_name).uniq.each do |so|

            name = "fix_for_so_#{so}"

            # Create a new dissolved layer 
            DissolvedFootprint.find_by(name: name).destroy if DissolvedFootprint.find_by(name: name).present?
            DissolvedFootprint.create(name: name)

            # Add those footprints to the dissolved layer
            sql = "UPDATE dissolved_footprints SET geom = (SELECT st_union(geom::geometry) AS the_geom from footprints WHERE camera_operator_name='#{so}') WHERE name='#{name}'"
            results = ActiveRecord::Base.connection.execute(sql)

            Easement.flown.joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='#{name}' AND st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").each do |easement|
                easement.tiles.flown.where(sensor_operator: nil).update(sensor_operator: so)
            end

        end

    end

    # def self.fix_geom

    #     ids = []
    
    #     Footprint.all.each do |fp|
    
    #         # footprints = Footprint.where(strip_frame: fp.strip_frame, state_id: fp.state_id).where.not(id: ids).order(:flight_date)
    
    #         # first = true
    #         # footprints.each do |fp|
    
    #         #     if first
    #         #         # the first footprint should always match
    #         #         if fp.tiles.count == 0
    #         #             # If it doesn't then quickly check that none of the associated do as well
    #         #             footprints.each do |fpx|
    #         #                 if fpx.tiles.count > 0
    #         #                     raise Exception, "#{fp.id} #{fp.strip_frame} is first and doesn't have any associated tiles"
    #         #                 end    
    #         #             end
    #         #         end
    #         #         first = false
    #         #     else
    #         #         if fp.tiles.count > 0
    #         #             raise Exception, "#{fp.id} #{fp.strip_frame} is not first and has associated tiles"
    #         #         end
    #         #     end
    
    #         #     ids << fp.id
    
    #         # end
    
    #         # fp.centroid_latitude = fp.geom.centroid.y
    #         # fp.centroid_longitude = fp.geom.centroid.x
    #         # fp.save!
    #         # if fp.errors
    #         #     # p fp.errors
    #         #     # errors << 
    #         # end

    #         fp.update!(
    #             centroid_latitude: nil,
    #             centroid_longitude: nil,
    #             centroid_latitude: fp.geom.centroid.y,
    #             centroid_longitude: fp.geom.centroid.x
    #         )

    #     end

    #     RejectedFootprint.all.each do |fp|

    #         fp.update!(
    #             centroid_latitude: fp.geom.centroid.y,
    #             centroid_longitude: fp.geom.centroid.x
    #         )
    #     end
    #     p "done"
    # end

    def self.update_county_state

        Footprint.update_all(notes: nil)

        Footprint.sl.order(:id).each do |footprint|
        # RejectedFootprint.sl.each do |footprint|

            # Query out the county the most majority is in and also include the state info
            sql = "select c.id as county_id, c.name as county_name, s.id as state_id, s.abv as state_abv, s.name as state_name from counties c INNER JOIN states s ON c.state_id = s.id
                where st_intersects(ST_GeomFromText('#{footprint.geom.to_s}'), c.geom) 
                order by (st_area(st_intersection(ST_GeomFromText('#{footprint.geom.to_s}'), c.geom))/st_area(ST_GeomFromText('#{footprint.geom.to_s}'))) DESC"
            result = ActiveRecord::Base.connection.execute(sql)

            if result.count > 0

                next if footprint.county_id == result[0]["county_id"]

                # Set the notes to keep track of the changes
                footprint.notes = "Originally #{footprint.county_name} in #{footprint.state_name}"

                # update the county info
                footprint.county_id = result[0]["county_id"]
                footprint.county_name = result[0]["county_name"]
                # update the state info
                footprint.state_id = result[0]["state_id"]
                footprint.state_name = result[0]["state_name"]

                # p "-----------"
                # p "County Name #{footprint.county_name}"
                # p "State Name #{footprint.state_name}"

                # Set the provisional due date
                provisional_due_date = 5.business_days.after(footprint.flight_date)

                # Find the associated vector metadatum
                vm = VectorMetadatum.find_or_create_by(
                    project: footprint.project, 
                    flight_date: footprint.flight_date,
                    service_name: "#{result[0]["state_abv"]}_PROVISIONAL_4B_#{footprint.flight_date.strftime("%Y%m%d")}",
                    state_name: result[0]["state_name"],
                    provisional_due_date: provisional_due_date,
                    state_id: result[0]["state_id"]
                )

                # Assocate the vector metadatum to the footprint
                footprint.vector_metadatum_id = vm.id

                # Save the fooptrint
                footprint.save!

            end

        end

        # Iterate all the vector metadatums and update the counts
        VectorMetadatum.sl.provisional_active.each do |vm|
            vm.update(count: vm.footprints.count)
        end

        p "done"

    end

    # def self.update_flight_date
    #     strip_frames = ["0001_1004", "0001_1005", "0001_1006", "0002_1010", "0002_1011", "0002_1012", "0003_1017", "0002_1015", "0004_1029", "0004_1033", "0004_1026", "0013_1057", "0013_1059", "0013_1062", "0015_1055", "0015_1052", "0006_1042", "0005_1038", "0005_1039", "0015_1051", "0014_1045", "0001_1002", "0001_1007", "0002_1013", "0002_1014", "0004_1030", "0004_1031", "0001_1008", "0001_1009", "0001_1001", "0001_1003", "0004_1028", "0013_1056", "0003_1021", "0003_1023", "0003_1024", "0003_1025", "0014_1047", "0014_1048", "0014_1049", "0014_1050", "0006_1043", "0006_1044", "0015_1054", "0005_1035", "0005_1037", "0003_1016", "0003_1020", "0013_1058", "0013_1060", "0004_1032", "0005_1034", "0013_1061", "0015_1053", "0005_1036", "0005_1040", "0003_1018", "0003_1019", "0004_1027", "0006_1041", "0003_1022", "0014_1046"]

    #     tile_id = []

    #     Footprint.where(flight_date: "2024-09-23", strip_frame: strip_frames).each do |footprint|

    #         footprint.update(flight_date: "2024-09-22")

    #         footprint.tiles.each do |tile|
    #             tile_id << tile.id
    #             tile.update(flight_date: "2024-09-22")
    #             tile.easement.update(flight_date: "2024-09-22")
    #         end

    #     end

    #     p tile_id.uniq.join(",")

    # end

    # def self.disassociate
    #     footprint = Footprint.find(26814)
    #     tiles = footprint.tiles

    #     footprint.destroy

    #     current_time = Time.now

    #     tiles.each do |tile|
    #         tile.update(at_start_date: current_time, at_done_date: current_time)
    #         tile.generate_median_flight_date_time
    #     end

    #     # Tile.find_by(poly_id: "7316449800HF7A0014")
    #     # Tile.find_by(poly_id: "7316440100HDZA0000d")
    # end

    def self.raw_tiff_compare params, user

        output = {
            pass: false,
            message: nil,
            count: 0,
        }

        project = params[:project]
        flight_date = Date.parse(params[:flight_date])

        # check if folder directory exists
        path = Task.build params[:input_directory]

        if !path
            output[:message] = "Invalid Input Directory: #{params[:input_directory]}"
            return output
        end

        result = []

        # Iterate all the tiffs in the immediate directory, do not go recursive
        Dir.glob("#{path}/*.tif").each do |file|
            p file

            filename = File.basename(file)
            filename_without_extension = File.basename(file, '.tif')

            obj = {
                filename: filename_without_extension,
                strip_frame: nil,
                flight_date: flight_date,
                state_abv: nil,
                county_name: nil,
                utm_zone: nil,
                has_tiles: false,
                rejected: false,
                has_fp: false,
                has_fc: false,
                has_rfp: false,
                has_rfc: false,
                no_sun_angle: nil
            }

            match = false

            # find the matching footprint
            fp = Footprint.includes(:frame_center).find_by(strip_frame: filename_without_extension, flight_date: flight_date, project: project)

            if fp.present?

                match = true

                fc = fp.frame_center

                obj[:has_fp] = true
                obj[:strip_frame] = fp.strip_frame
                obj[:state_abv] = fp.state_abv
                obj[:county_name] = fp.county_name
                obj[:utm_zone] = fp.utm_zone
                obj[:has_tiles] = fp.associated
                obj[:has_fc] = fc.present? ? true : false
                obj[:no_sun_angle] = !fc.sun_angle_error if fc.present?
            else
                # check rejected footprints
                rfp = RejectedFootprint.includes(:rejected_frame_center).find_by(strip_frame: filename_without_extension, flight_date: flight_date, project: project)

                if rfp.present?

                    match = true

                    rfc = rfp.rejected_frame_center

                    obj[:has_rfp] = true
                    obj[:rejected] = true
                    obj[:has_tiles] = rfp.associated
                    obj[:strip_frame] = rfp.strip_frame
                    obj[:state_abv] = rfp.state_abv
                    obj[:county_name] = rfp.county_name
                    obj[:utm_zone] = rfp.utm_zone
                    obj[:has_rfc] = rfc.present? ? true : false
                    obj[:no_sun_angle] = !rfc.sun_angle_error if rfc.present?
                end
            end

            if !match
                obj = {
                    filename: filename_without_extension,
                    strip_frame: filename_without_extension,
                    flight_date: flight_date,
                    state_abv: nil,
                    county_name: nil,
                    utm_zone: nil,
                    associated: nil,
                    rejected: nil,
                    has_fp: nil,
                    has_fc: nil,
                    has_rfp: nil,
                    has_rfc: nil,
                    no_sun_angle: nil
                }
            end

            result << obj

        end

        output[:result] = result

        if result.count > 0
            output[:count] = result.count
            output[:pass] = true
        else
            output[:message] = "No Tiffs found in #{params[:input_directory]}"
        end

        output

    end


    def self.find_and_update

        # 7/1 - 7/2
        strip_frames = ["0299_8806", "0299_8807", "0299_8808", "0299_8809"]
        old_date = "2024-07-01"
        new_date = "2024-07-02"
        alter_poly_ids = ["6693270000FT9"]
        state_id = 24
        company_id = 1
        new_county_flight_date = "2024-07-02"

        # ==================

        poly_ids = []

        # Find the matching footprints
        footprints = Footprint.where(flight_date: old_date, flown_by_id: company_id, strip_frame: strip_frames, state_id: state_id)

        p "Footprint Count: #{footprints.count}"

        # Dissolve the footprints
        # DissolvedFootprint.footprints footprints.pluck(:id), "NRI/SL"

        Tile.where(poly_id: alter_poly_ids, flight_date: old_date, flown_by_id: company_id, state_id: state_id).each do |tile|
            poly_ids << tile.poly_id
            tile.update(flight_date: new_date, report_date: nil, associate_date: nil)
            tile.easement.update(flight_date: new_date)

            # if the county flight date matches the old flight date then update it
            if new_county_flight_date
                tile.update(county_flown_date: new_county_flight_date)
            end
        end

        # update the footprints
        footprints.update_all(flight_date: new_date)

        pp poly_ids
    end

    def self.find_and_remove_invalid_associations
        result = []

        # iterate all flown tiles
        Tile.flown.each do |tile|

            # check if the associated tiles do not match the same flight date and if so then disassociate
            tile.footprints.where.not(flight_date: tile.flight_date).each do |fp|

                result << {fp: fp.id, fp_fd: fp.flight_date, tile: tile.id, tile_fd: tile.flight_date, state: tile.state_abv} 

                fp.update(notes: "mismatch")
                tile.update(notes: "mismatch")

                # TileFootprint.find_by(tile_id: tile.id, footprint_id: fp.id).destroy
            end

        end

        p result.size
        pp result
    end
end
