class PhotoIndex < ApplicationRecord
    include Concerns::Archive
    include Rails.application.routes.url_helpers

    # Associations
    belongs_to :upload
    belongs_to :camera
    belongs_to :plane
    belongs_to :footprint, optional: true
    belongs_to :rejected_footprint, optional: true
    belongs_to :flown_by, class_name: 'Company'
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs

    # Validations
    validates :strip, :frame, :strip_frame, :flown_by_name, :camera_name, :flight_date, :flight_date_time, :gpstime, :sun_angle, :latitude, :longitude, :geom, presence: true
    validates :footprint_id, :rejected_footprint_id, uniqueness: true, allow_nil: true

    # Scopes
    scope :sl,                      -> { where(sl: true) }
    scope :nri,                     -> { where(nri: true) }
    scope :naip,                    -> { where(naip: true) }
    scope :nri_sl,                  -> { where(sl: true, nri: true) }
    scope :rejected,                -> { where(sun_angle_error: true) }
    scope :approved,                -> { where(sun_angle_error: false) }
    scope :has_footprints,          -> { where.not(footprint_id: nil) }
    scope :no_footprints,           -> { where(footprint_id: nil) }
    scope :has_rejected_footprints, -> { where.not(rejected_footprint_id: nil) }
    scope :no_rejected_footprints,  -> { where(rejected_footprint_id: nil) }

    def self.prepare_import params, user

        response = {
            pass: false,
            message: nil
        }

        path = nil
        file = nil

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Check if the project is set
                # if (!["NRI/SL"].include? params[:project])
                #     raise Exception, "Invalid Project (#{params[:project]}), must be #{Rails.application.secrets.active_projects.join(", ")}"
                # end

                # # Validate the filename
                # arr = params[:file].original_filename.split("_")

                # # Check if the second array element is a company
                # company = Company.find_by(alias: arr[1])
                # if company.nil? || company.id != params[:flown_by_id].to_i
                #     if company.nil? 
                #         raise Exception, "Contractor #{arr[1]} does not exist in application"
                #     elsif company.id != params[:flown_by_id].to_i
                #         raise Exception, "Contractor #{arr[1]} does not match specified Flown By Company in Form"
                #     end
                # end

                # # Check the Camera
                # camera = Camera.find_by(id: params[:camera_id])
                # camera_filename = Camera.find_by(name: arr[2])
                # if camera.id != camera_filename.id
                #     raise Exception, "Camera extract from Filename does not match the Camera supplied by the form"
                # end

                # if params[:flight_date].nil? 
                #     raise Exception, "Missing Flight Date"
                # end

                # Check if the second array element is a company
                company = Company.find_by(id: params[:flown_by_id].to_i)
                if company.nil? 
                    raise Exception, "Contractor does not exist in application"
                end

                # Check the Camera
                if params[:camera_id] == "auto"
                    camera = "auto"
                else
                    camera = Camera.find_by(id: params[:camera_id])
                    if camera.nil?
                        raise Exception, "Camera extract from Filename does not match the Camera supplied by the form"
                    end
                end

                # Copy the file to the server
                # Get the folder name by converting the current time to seconds
                folder = Time.now.to_i

                path = "#{Rails.root}/assets/photo_index/#{folder}"

                # Create a folder if it doesn't exist
                FileUtils.mkdir_p(path)
                FileUtils.mkdir("#{path}/original")

                file = "#{path}/original/#{File.basename(params[:file].original_filename)}"

                File.write("#{path}/original/#{File.basename(params[:file].original_filename)}", File.read(params[:file].path))

                response = {
                    pass: true,
                    message: "Text file has been uploaded to the server and supplied form has been validated. Import process has been added to Job Queue. You will receive a message when it is completed."
                }

            rescue Exception => exception
                Rails.logger.error "Photo Index Import Prep Error: #{exception.message}"
                response[:pass] = false
                response[:message] = exception.message

                # Delete the files
                FileUtils.rm_rf("#{path}/") if path

                raise ActiveRecord::Rollback
            end
        end

        if response[:pass] && path && file
            PhotoIndex.delay.import params, path, file, user
        end

        response

    end

    def self.import params, path, file, user

        p "Import"

        # create an Error array to hold any messages
        output = {
            pass: false,
            errors: [],
            count: 0,
            rejected: 0,
            sun_angle_failed: 0,
            easement_count: 0
        }

        job = Job.create(
            started_at: Time.now,
            message: "Processing Request...",
            active: true,
            process_type: "Photo Index Import (#{params[:project]})",
            filename: File.basename(file),
            creator: user
        )

        # Set the project
        project = params[:project]
        count = 0

        current_time = Time.now
        # Stores variables for the job process
        process_success = false
        error_message = "Something went wrong. Contact Programming"
        auto_detect_camera = true

        uploads = {}

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Validate the filename
                arr = params[:file].original_filename.split("_")

                # get the camera parameter
                # => if it's "auto" then it should only be the ASI cameras

                if params[:camera_id] == "auto"
                    camera = "auto"
                else
                    # Check the Camera
                    camera = Camera.find_by(id: params[:camera_id])
                    if camera.nil?
                        raise Exception, "Camera extract from Filename does not match the Camera supplied by the form"
                    end
                    auto_detect_camera = false
                end

                company = Company.find_by(id: params[:flown_by_id].to_i)
                if company.nil? 
                    raise Exception, "Contractor does not exist in application"
                end

                # Create a new History record
                history = History.new
                history.action_type = "Photo Index Upload (#{project})"
                history.creator = user
                history.save

                # Copy the file to the server
                # Get the folder name by converting the current time to seconds
                folder = Time.now.to_i

                # Create a new Upload instance
                upload = Upload.create(
                    uploader: user,
                    folder_path: "#{path}/",
                    upload_type: "PhotoIndex",
                )

                out_factory = RGeo::Geographic.spherical_factory(srid: 4326, proj4: '+proj=longlat +datum=WGS84 +no_defs' )

                # p "---------"
                # p file
                # p "---------"

                valid_footprints = []
                footprints_to_be_rejected = []

                skipped = 0

                File.open(file, "r") do |f|

                    f.each_line.with_index do |line, index|

                        p "#{index} - #{line.tr("\r\n","")}"

                        # split the array by commans
                        arr = line.split(",")

                        # skip if the array does not have 7 fields
                        # next if arr.size != 7

                        # skip if it's the header line
                        next if line[0..2] == "UTC"

                        # # skip if the line is a free shot
                        # next if line.downcase.include? "free shot"

                        # skip the first 
                        next if index < 7

                        # Remove the newlines from end of line
                        line = line.tr("\r\n","")

                        next if line.length === 0

                        # split the array by commans
                        arr = line.split(",")

                        record_flight_date = Date.strptime(arr[4], "%m/%d/%Y")

                        p "======"
                        p "gpstime: #{arr[1]}"
                        p "strip: #{arr[2]}"
                        p "frame: #{arr[3]}"
                        # p "flight_date: #{arr[4]}"
                        p "flight_date: #{record_flight_date}"
                        p "latitude: #{arr[6]}"
                        p "longitude: #{arr[5]}"
                        p "Camera: #{arr[7]}"

                        # next

                        # # if the line is not 7 indices then throw error
                        # if arr.size != 5
                        #     raise Exception, "Row malformation found in txt file, please check the file for errors"
                        # end

                        # check if the flight date in the filename matches the record
                        # if flight_date != record_flight_date
                        #     raise Exception, "Filename flight date does not match record flight date"
                        # end

                        free_shot = arr[2].downcase == "free shot" ? true : false
                        
                        # if free shot skip it
                        if free_shot
                            # strip = "FREE_SHOT"
                            # frame = arr[3]
                            # strip_frame = strip
                            skipped += 1
                            next
                        else
                            strip = "#{"0" * (4 - arr[2].to_s.length)}#{arr[2]}"
                            frame = arr[3]

                            # if the frame is greater than 5 digits then return the last 4 digits off 
                            if frame.length > 4
                                frame = frame[-4..-1]
                            end

                            if frame.length < 4
                                # Buffer the second array with "0" to be 4 digits
                                frame = "#{"0" * (4 - frame.length)}#{frame}"
                            end

                            # frame = "#{"0" * (4 - arr[3].to_s.length)}#{arr[3]}"
                            strip_frame = "#{strip}_#{frame}"
                        end
                        latitude = arr[6].to_f.round(6)
                        longitude = arr[5].to_f.round(6)
                        gpstime = arr[1]

                        if auto_detect_camera
                            if arr[7].include? "_"
                                camera = Camera.find(24)
                                plane = Plane.find(4)
                            else
                                camera = Camera.find(4)
                                plane = Plane.find(1)
                            end
                        end

                        p "-------"
                        p camera
                        p "-------"

                        # If Free Shot then check if it's a dup based on the gpstime, lat, and long

                        if PhotoIndex.where(strip_frame: strip_frame, flight_date: record_flight_date, gpstime: gpstime).count > 0
                            p "Found duplicate strip frame: #{strip_frame}. Skipping"
                            skipped += 1
                            next
                        end

                        # start building the PhotoIndex
                        record = PhotoIndex.new(
                            project: params[:project],
                            strip: strip,
                            frame: frame,
                            strip_frame: strip_frame,
                            flown_by_name: company.alias,
                            camera_name: camera.name,
                            plane_name: plane.name,
                            flight_date: record_flight_date,
                            gpstime: gpstime,
                            recorded_sun_angle: nil,
                            latitude: latitude, 
                            longitude: longitude,
                            geom: RGeo::Geographic.spherical_factory(srid: 4326).point(longitude, latitude),
                            camera: camera,
                            plane: plane,
                            # upload: upload,
                            flown_by: company,
                            free_shot: free_shot
                        )

                        upload_key = "#{record_flight_date.to_s}#{record.camera_id}"

                        if !uploads[upload_key]

                            uploads[upload_key] = Upload.create(
                                folder_path: "#{path}/",
                                upload_type: "PhotoIndex",
                                uploader: user
                            )
                        end
                        record.upload = uploads[upload_key]

                        pp record

                        # p record.flight_date

                        # Calcualte the GPS Time
                        # => Get the Sunday of the week the flight date starts on
                        # => Add the GPS Time to it as seconds
                        record.flight_date_time = record.flight_date.beginning_of_week(:sunday) + record.gpstime.to_f.seconds

                        if record.flight_date_time.strftime("%F") != record.flight_date.strftime("%F")
                            raise Exception, "Photo Index's (Strip Frame: #{record.strip_frame}) GPS Time (#{record.flight_date_time.strftime("%F")}} does not match the provided Flight Date (#{record.flight_date})!"
                        end

                        # Get the sun angle 
                        record.sun_angle, azimuth = Solar.position(record.flight_date_time, record.longitude, record.latitude)

                        # Check if the sun angle is equal to or greater than the minimum allowed
                        record.sun_angle_error = false
                        if record.sun_angle < Rails.application.secrets.min_sun_angle
                            p "#{record.strip_frame} - Sun Angle below #{Rails.application.secrets.min_sun_angle}: #{record.sun_angle}"
                            record.sun_angle_error = true if !free_shot
                        end

                        # save the record
                        if !record.save
                            raise Exception, record.errors.full_messages.to_sentence
                        end
                        count += 1

                        history.photo_indices << record
                    end
                end

                # p "_________"
                # p upload.photo_indices.count
                # p upload.photo_indices.approved.count
                # p upload.photo_indices.rejected.count
                # p "_________"

                uploads.each do |key, upload|

                    # check if there were any 
                    if upload.photo_indices.approved.count == 0
                        upload.destroy
                        # raise Exception, "No Photo Indices were imported most likely due to duplicates. Upload aborted."
                    end

                end

                message = "Successfully imported #{count} Photo Indices from #{params[:file].original_filename}. #{history.photo_indices.approved.count} contained valid sun angles."

                if skipped > 0
                    message += " #{skipped} Photo Indices were skipped because of duplicates or Free Shots."
                end

                key = uploads.keys.first

                job.update(
                    finished_at: Time.now,
                    active: false,
                    success: true,
                    upload: uploads[key],
                    message: message
                )

                # Update the history
                history.update(message: message)

                uploads.each do |key, upload|
                    history.uploads << upload

                    # Build the Export of Photo ID
                    PhotoIndex.build_export_file upload
                end

                # Log and send email
                Mailbox.ship({
                    users: MailGroup.find_by(name: "Photo Index").users | [user],
                    subject: "Photo Index Import Succeeded",
                    message: message.html_safe,
                    route: Rails.application.routes.url_helpers.show_timeline_url(history.id, only_path: false, host: Rails.application.secrets.host)
                })

                # # Send out email about import
                # Rails.application.secrets.photo_index.each do |user|
                #     email_user = User.find_by(user)
                #     next if email_user.nil?
                #     PostmasterMailer.notify(email_user, message.html_safe, "USDA #{Rails.application.secrets.project_year}: Photo Index have been imported - #{Time.now.strftime("%m/%d/%Y")}", Rails.application.routes.url_helpers.show_timeline_url(history.id, only_path: false, host: Rails.application.secrets.host)).deliver
                # end

                process_success = true

            rescue Exception => exception
                Rails.logger.error "Photo Index Import Error: #{exception.message}"
                error_message = exception.message

                # # Delete the Upload and History
                # upload.destroy if upload.present?
                # history.destroy if history.present?

                p "-----------"
                p exception.backtrace.count
                exception.backtrace.each do |x|
                    next if !x.include? "photo_index.rb"
                    x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
                p [$1,$2,$4]
                end
                p "-----------"

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
                users: [user],
                subject: "Photo Index Import Failed",
                message: "Photo Index Import Failed, error encountered is listed below: <br/><br/>#{error_message}".html_safe
            })

            # Send email to notified it failed
            # PostmasterMailer.notify(user, "Photo Index Import Failed, error encountered is listed below: <br/><br/>#{error_message}".html_safe, "USDA #{Rails.application.secrets.project_year}: Photo Index Import Failed - #{Time.now.strftime("%m/%d/%Y")}").deliver

            # Update the Job
            job.update(
                finished_at: Time.now,
                active: false,
                success: false,
                message: "Import Failed",
                upload: nil,
                error_message: error_message
            )

        end

        p "done"

    end

    def self.fix_missing_associations
        PhotoIndex.where(utm_id: nil).each do |record|

            p record.id

            footprint = nil
            if record.footprint_id
                footprint = record.footprint 
            else
                footprint = record.rejected_footprint
            end

            if footprint

                # update attributes
                record.county_name = footprint.county_name
                record.state_name = footprint.state_name
                record.utm_zone = footprint.utm_zone

                record.county_id = footprint.county_id
                record.state_id = footprint.state_id
                record.utm_id = footprint.utm_id

            else
                # query the county and UTM zone
                sql = "select id, zone from utms u where st_intersects(ST_GeomFromText('#{record.geom.to_s}'), u.geom)"
                result = ActiveRecord::Base.connection.execute(sql)

                record.utm_id = result[0]["id"]
                record.utm_zone = "#{result[0]["zone"]}N"

                # Get the footprint County

                # Query out the county the most majority is in and also include the state info
                sql = "select c.id as county_id, c.name as county_name, s.id as state_id, s.abv as state_abv, s.name as state_name from counties c INNER JOIN states s ON c.state_id = s.id
                    where st_intersects(ST_GeomFromText('#{record.geom.to_s}'), c.geom)"
                result = ActiveRecord::Base.connection.execute(sql)

                if result.count > 0
                    # update the county info
                    record.county_id = result[0]["county_id"]
                    record.county_name = result[0]["county_name"]
                    # update the state info
                    record.state_id = result[0]["state_id"]
                    record.state_name = result[0]["state_name"]
                end
            end
            record.save!

        end
    end

    def self.list_rejected

        arr = ["Company, Flight Date, State, Strip Frame, Sun Angle"]

        PhotoIndex.rejected.where("flight_date > '2022-10-01'").order(:strip_frame, :flight_date).each do |pi|
            arr << "#{pi.flown_by_name}, #{pi.flight_date}, #{pi.state_name}, #{pi.strip_frame}, #{pi.sun_angle.to_f}"
        end

        pp arr

    end

    def self.build_export_file upload
        # Takes the uploaded photo indices and splits them by flight date and sort by gpstime

        # update the path to include a new folder for the photo id
        path = "#{upload.folder_path}/photo_id/"

        # Create a folder if it doesn't exist
        FileUtils.mkdir_p("#{path}") unless File.directory?(path)

        # get the min/max dates
        flight_dates = upload.photo_indices.select(:flight_date).order(:flight_date).pluck(:flight_date).uniq
        date_range = flight_dates.size == 1 ? flight_dates.first.strftime("%Y%m%d") : "#{flight_dates.first.strftime("%Y%m%d")}_#{flight_dates.last.strftime("%Y%m%d")}"

        # Pluck the state_ids
        state_ids = upload.photo_indices.select(:state_id).order(:state_name).pluck(:state_id).uniq

        # Set the formated date to a string to be reused
        time_string = Time.now.strftime("%Y%m%d")
        photo_id_file_name = "#{date_range}_Photo_ID_#{State.select(:abv).where(id: state_ids).order(:abv).pluck(:abv).uniq.join("_")}.txt"

        # Create the files
        photo_id_file = File.open("#{path}/#{photo_id_file_name}", "w+")

        obj = {}
        unknown = {}

        # Iterate the photo indices and build grouping obj
        upload.photo_indices.order(:gpstime).each do |pi|

            if pi.state_name.nil?
                unknown["#{pi.utm_zone} | Unknown State | #{pi.flight_date}"] = [] if unknown["#{pi.utm_zone} | Unknown State | #{pi.flight_date}"].nil?

                # add the photo indice values to the array
                unknown["#{pi.utm_zone} | Unknown State | #{pi.flight_date}"] << {
                    gpstime: pi.gpstime.to_f,
                    strip_frame: pi.strip_frame,
                    flight_date: pi.flight_date.strftime("%-m/%-d/%Y"),
                    latitude: pi.latitude.to_f,
                    longitude: pi.longitude.to_f
                }

                next
            end

            # Build the UTM Zone object
            obj["#{pi.utm_zone} | #{pi.state_name} | #{pi.flight_date}"] = [] if obj["#{pi.utm_zone} | #{pi.state_name} | #{pi.flight_date}"].nil?

            # add the photo indice values to the array
            obj["#{pi.utm_zone} | #{pi.state_name} | #{pi.flight_date}"] << {
                gpstime: pi.gpstime.to_f,
                strip_frame: pi.strip_frame,
                flight_date: pi.flight_date.strftime("%-m/%-d/%Y"),
                latitude: pi.latitude.to_f,
                longitude: pi.longitude.to_f
            }

        end

        if !unknown.blank?

            unknown.each do |key, array|

                photo_id_file.puts("")
                photo_id_file.puts(" -------   !IMPORTANT!   -------")
                photo_id_file.puts(" - COULD NOT FIND A MATCHING STATE, PLEASE CONFIRM IN QGIS MAP -")
                photo_id_file.puts("")
                photo_id_file.puts(" ####### | UTM ZONE #{key} | #######")
                photo_id_file.puts("")

                array.each do |record|
                    photo_id_file.puts("#{record[:gpstime]} #{record[:strip_frame]} #{record[:flight_date]} #{record[:latitude]} #{record[:longitude]}")
                end

                photo_id_file.puts("")
                photo_id_file.puts(" --------------------------------")
            end
        end

        # Iterate the obj
        obj.each do |key, array|

            photo_id_file.puts("")
            photo_id_file.puts("")
            photo_id_file.puts(" ###### | UTM ZONE #{key} | ######")
            photo_id_file.puts("")
            photo_id_file.puts("")

            array.each do |record|
                photo_id_file.puts("#{record[:gpstime]} #{record[:strip_frame]} #{record[:flight_date]} #{record[:latitude]} #{record[:longitude]}")
            end

        end

    end

    def self.retrieve_photo_id upload

        # Get the only .txt file in the upload folder path photo_index_id folder
        path = "#{upload.folder_path}/photo_id/"

        Dir["#{path}/*.txt"][0]

    end

    def self.auto_reject_tiles flight_date, upload, camera, flown_by, user, project
        p "----------------"
        p "auto_reject_tiles"
        p "project: #{project}"
        p "----------------"

        output = {
            pass: true,
            error: nil
        }

        message = "Auto Rejection during Frame Center import"

        # Start a Transaction Block
        ActiveRecord::Base.transaction(joinable: false, requires_new: true) do
            begin

                pi_reject_obj = {
                    flight_date: flight_date.all_day, 
                    camera: camera, 
                    flown_by: flown_by
                }

                if project == "NRI"
                    pi_reject_obj[:nri] = true
                elsif project == "SL"
                    pi_reject_obj[:sl] = true
                end

                photo_indices_to_reject = upload.photo_indices.rejected.where(pi_reject_obj)

                # Get the Rejected Footprints that have associated frame centers that match flight date, state, camera, and company
                footprints = photo_indices_to_reject.map {|pi| pi.footprint}

                # Create new history object to store all rejections
                history = History.new
                history.action_type = "Auto-Reject Tiles"
                history.creator = user
                history.save

                p "---------"
                p "upload: #{upload.id}"
                p "photo_indices_to_reject: #{photo_indices_to_reject.pluck(:strip_frame)}"
                p "total photo_indices: #{upload.photo_indices.count}"
                p "footprints count: #{footprints.count}"
                p "---------"

                footprints.each do |footprint|

                    p "Reject Footprint: #{footprint.strip_frame}"

                    # Check the footprint is SL only
                    if footprint.project == "NAIP"
                        raise Exception, "Footprint: #{footprint.id} is marked as NAIP, not NRI/SL. Cannot reject" 
                    end

                    frame_center = footprint.frame_center

                    # Reject the Footprint and return the new rejected_footprint
                    rejected_footprint = RejectedFootprint.reject footprint, message

                    p "-----------"
                    p "Rejected Footprint"
                    p rejected_footprint
                    p "-----------"

                    if !rejected_footprint
                        raise Exception, "Footprint: #{footprint.id} could not be rejected!"
                    end

                    # check for the photo index that has the original id and update it with the rejected footprint id
                    PhotoIndex.rejected.where(footprint_id: rejected_footprint.original_id).update(
                        rejected_footprint_id: rejected_footprint.id,
                        footprint_id: nil
                    )

                    # Reject the associated Frame Center of the footprint
                    if frame_center
                        rejected_frame_center = RejectedFrameCenter.reject frame_center, message

                        if !rejected_frame_center
                            # raise "Frame Center #{fc.id} could not be rejected!"
                            # raise ActiveRecord::Rollback
                            raise Exception, "Frame Center #{fc.id} could not be rejected!"
                        end

                        history.rejected_frame_centers << rejected_frame_center
                    end

                    # # Reject the associated Frame Center
                    # rejected_frame_center = RejectedFrameCenter.reject frame_center, message

                    # if !rejected_frame_center
                    #     raise Exception, "Frame Center (StripFrame: #{frame_center.strip_frame}) could not be rejected!"
                    # end

                    # Add rejected footprint and rejected frame centers to history
                    history.rejected_footprints << rejected_footprint
                    # history.rejected_photo_indices << rejected_frame_center

                end

                reject_footprint_obj = {
                    flight_date: flight_date, 
                    camera: camera, 
                    flown_by: flown_by
                }

                if project == "NRI"
                    reject_footprint_obj[:nri] = true
                elsif project == "SL"
                    reject_footprint_obj[:sl] = true
                end

                # p "<><><><><><><><><>"
                # pp reject_footprint_obj
                # p "<><><><><><><><><>"

                # Find all footprint uploads in the system that matches the scoped requirements
                footprint_ids = Footprint.exclude_geom.select(:id).where(reject_footprint_obj).pluck(:id).uniq

                p "==========="
                p "footprint_ids: #{footprint_ids}"
                p "==========="

                DissolvedFootprint.find_or_create_by(name: "photo_indices").update(geom: nil)

                # check if the footprints exist and if not then query the easements covered by the rejected footprints
                if footprint_ids.size == 0

                    p "--------------"
                    p "No Footprints, dissolve rejected footprints instead"
                    p "Rejected Footprint ID: #{history.rejected_footprints.pluck(:id).uniq.join(", ")}"
                    p "--------------"

                    # Dissolve all the rejected footprints 
                    sql = "UPDATE dissolved_footprints SET geom = (SELECT ST_Multi(st_union(ST_Multi(geom::geometry))) AS the_geom from rejected_footprints where ST_IsValid(geom::geometry)
                        AND rejected_footprints.id IN (#{history.rejected_footprints.pluck(:id).uniq.join(", ")}) ) WHERE name='photo_indices'"
                    ActiveRecord::Base.connection.execute(sql)

                    # select out easements that ARE contained within the dissolved layer
                    easements = Easement.flown.includes(:tiles).joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='photo_indices' 
                        AND st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").where(
                            project: project, flight_date: flight_date, tiles: {camera: camera, flown_by: flown_by}
                        )

                else

                    # Dissolve all the footprints 
                    sql = "UPDATE dissolved_footprints SET geom = (SELECT ST_Multi(st_union(ST_Multi(geom::geometry))) AS the_geom from footprints where ST_IsValid(geom::geometry)
                        AND footprints.id IN (#{footprint_ids.uniq.join(", ")}) ) WHERE name='photo_indices'"
                    ActiveRecord::Base.connection.execute(sql)

                    # select out easements that ARE NOT contained within the dissolved layer
                    easements = Easement.flown.includes(:tiles).joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='photo_indices' 
                        AND not st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").where(
                            project: project, flight_date: flight_date, tiles: {camera: camera, flown_by: flown_by}
                        )


                end

                p "-----------"
                p "EASEMENTS: #{easements.count}"
                p "-----------"

                # Reject the Tiles and associated footprints/frame centers
                output, history = Rejection.reject_tiles easements.pluck(:poly_id), flight_date, history, false, message

                # set the message for history
                history.message = "Auto-Rejected #{history.rejected_tiles.count} Tiles, #{history.rejected_footprints.count} Footprints, and #{history.rejected_frame_centers.count} Frame Centers via Photo Index Import."
                history.save

                output = {
                    pass: true,
                    message: history.message,
                    rejected_tiles: history.rejected_tiles
                }
                # return history

            rescue => exception
                Rails.logger.error "Frame Center Auto Reject Error: #{exception.message}"
                ActiveRecord::Rollback
                return {
                    pass: false,
                    error: exception.message
                }
            end
        end

    end


    # def self.auto_reject_tiles footprints, project, user=User.first

    #     # find the tiles of the associated footprints
    #     # reject the tiles
    #     # check if any of the rejected footprints are still existing and reject those too

    #     # Create new history object to store all rejections
    #     history = History.new
    #     history.action_type = "Photo Index Auto-Reject Tiles"
    #     history.creator = user
    #     history.save

    #     tiles_to_review = {}

    #     message = "Auto Rejection during Photo Index import"

    #     p "photo index auto reject tiles"
    #     p "#{footprints}"
    #     p "----------------"

    #     footprints.each do |footprint|

    #         # Check the footprint is SL only
    #         if footprint.project == "NAIP"
    #             raise Exception, "Footprint: #{footprint.id} is marked as NAIP, not NRI or SL. Cannot reject" 
    #         end

    #         # Create a new array scoped based on the flight date
    #         tiles_to_review[footprint.flight_date.strftime("%F")] = [] if tiles_to_review[footprint.flight_date.strftime("%F")].nil?

    #         # pull the associated tiles out to check if they should be rejected
    #         tiles_to_review[footprint.flight_date.strftime("%F")] |= Tile.select(:poly_id).where(id: TileFootprint.where(footprint_id: footprint.id).pluck(:tile_id)).pluck(:poly_id)
    #     # end

    #     # # Check to make sure all the footprints were rejected
    #     # # => if there is any orphaned footprints they will not get collected by the tile rejection process
    #     # Footprint.where(id: footprints.pluck(:id)).each do |footprint|
    #         p footprint.id

    #         # get the frame center before deleting the footprint
    #         framecenter = footprint.frame_center

    #         # Reject the Footprint and return the new rejected_footprint
    #         rejected_footprint = RejectedFootprint.reject footprint, message

    #         if !rejected_footprint
    #             raise Exception, "Footprint: #{footprint.id} could not be rejected!"
    #         end

    #         # Reject the associated Frame Center of the footprint
    #         if framecenter
    #             rejected_frame_center = RejectedFrameCenter.reject framecenter, message

    #             if !rejected_frame_center
    #                 # raise "Frame Center #{fc.id} could not be rejected!"
    #                 # raise ActiveRecord::Rollback
    #                 raise Exception, "Frame Center #{fc.id} could not be rejected!"
    #             end

    #             history.rejected_frame_centers << rejected_frame_center
    #         end

    #         history.rejected_footprints << rejected_footprint
    #     end
        
    #     p "++++++++++++"
    #     p "Remaining footprints: #{Footprint.where(id: footprints.pluck(:id)).count}"

    #     p "TILES: #{tiles_to_review}"

    #     tiles_to_review.each do |key, poly_ids|
    #         # p key

    #         tiles_to_reject = []

    #         # iterate the array
    #         poly_ids.each do |poly_id|

    #             tile = Tile.includes(:footprints).find_by(poly_id: poly_id)
    #             p "Footprints: #{tile.footprints.pluck(:id)}"

    #             # check if there are any footprints
    #             # => if not then add to the tiles_to_reject
    #             if tile.footprints.count == 0
    #                 tiles_to_reject << poly_id
    #                 next
    #             end

    #             # Dissolve the associated footprints
    #             DissolvedFootprint.footprints tile.footprints.pluck(:id), project 

    #             # check if compeltely covered
    #             easement_to_reject = Easement.flown.includes(:tiles).joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='footprints' 
    #                 AND not st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").where(
    #                     project: project, poly_id: poly_id
    #                 ).group_by(&:flight_date)

    #             # if the easement is found then mark it to be rejected
    #             tiles_to_reject << poly_id if easement_to_reject.count == 1
            
    #         end

    #         p "REJECTING: #{tiles_to_reject}"

    #         if tiles_to_reject.size > 0
    #             output, history = Rejection.reject_tiles tiles_to_reject, key, history, false, message
    #         end
            
    #     end

    #     history.update(message: "Auto-Rejected #{history.rejected_tiles.count} Tiles, #{history.rejected_footprints.count} Footprints, and #{history.rejected_frame_centers.count} Frame Centers")

    #     p "done"

    # end

end
