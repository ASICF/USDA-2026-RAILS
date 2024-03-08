class FrameCenter < ApplicationRecord
    include Concerns::Archive
    include Rails.application.routes.url_helpers

    # Associations
    belongs_to :county, optional: true
    belongs_to :state, optional: true
    belongs_to :utm, optional: true
    belongs_to :upload
    belongs_to :camera
    belongs_to :plane
    belongs_to :footprint
    belongs_to :project_state, class_name: 'State', optional: true
    belongs_to :flown_by, class_name: 'Company'
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs
    has_many :rejected_frame_centers

    # Scopes
    # => Boolean Based Status Scopes
    # scope :matched,     -> { where.not(tile_id: nil) }
    # scope :not_matched, -> { where(tile_id: nil) }
    scope :build_geom,  -> { where(build_geom: true) }

    # Scopes
    scope :sl, -> { where(sl: true) }
    scope :nri, -> { where(nri: true) }
    scope :naip, -> { where(naip: true) }
    scope :nri_sl, -> { where(sl: true, nri: true) }
    scope :rejected,        -> { where(sun_angle_error: true) }
    scope :approved,        -> { where(sun_angle_error: false) }
    scope :has_rejections,  -> {includes(:rejected_tiles).where.not(rejected_tiles: { id: nil })}
    scope :has_footprint,  -> { where.not(footprint_id: nil) }
    scope :exclude_geom,    -> { select( FrameCenter.attribute_names - ['geom'] ) }

    def rejected?
        self.sun_angle_error
    end

    def self.prepare_import params, user

        response = {
            pass: false,
            message: nil
        }

        output_path = nil
        path = nil
        file = nil

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Check if the project is set
                if (!["NRI/SL"].include? params[:project])
                    raise Exception, "Invalid Project (#{params[:project]}), must be #{Rails.application.secrets.active_projects.join(", ")}"
                end

                # Validate the filename
                arr = params[:file].original_filename.split("_")

                # Check to make sure the filename flight date matches the form flight date
                file_date = Date.parse(arr[0])
                if file_date != Date.parse(params[:flight_date])
                    raise Exception, "Filename flight date does not match Form Flight Date"
                end

                # Check if the second array element is a company
                company = Company.find_by(alias: arr[1])
                if company.nil? || company.id != params[:flown_by_id].to_i
                    if company.nil? 
                        raise Exception, "Contractor #{arr[1]} does not exist in application"
                    elsif company.id != params[:flown_by_id].to_i
                        raise Exception, "Contractor #{arr[1]} does not match specified Flown By Company in Form"
                    end
                end

                # Make sure the camera exists
                camera = Camera.find_by(id: params[:camera_id])
                if camera.nil? || (camera.name.downcase != arr[2].downcase)
                    raise Exception, "Camera name does not match the Filename"
                end

                # Check if the third element is a utm zone
                utm_zone = Utm.find_by(zone: arr[3].tr("z", ""))
                if utm_zone.nil?
                    raise Exception, "UTM Zone #{arr[3]} is not a valid UTM Zone"
                end

                # Check the output path and make sure it works there
                if !Dir.exist?(Rails.application.secrets.nri_eo_splitter_path)
                    raise Exception, "Output NRI EO Path (#{Rails.application.secrets.nri_eo_splitter_path}) does not exist"
                end
                if !Dir.exist?(Rails.application.secrets.sl_eo_splitter_path)
                    raise Exception, "Output SL EO Path (#{Rails.application.secrets.sl_eo_splitter_path}) does not exist"
                end

                # Copy the file to the server
                # Get the folder name by converting the current time to seconds
                folder = Time.now.to_i

                path = "#{Rails.root}/assets/frame_centers/#{folder}"

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
                Rails.logger.error "Frame Center Import Prep Error: #{exception.message}"
                response[:pass] = false
                response[:message] = exception.message

                p "-----------"
                p exception.backtrace.count
                exception.backtrace.each do |x|
                    next if !x.include? "frame_center.rb"
                    x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
                   p [$1,$2,$4]
                end
                p "-----------"

                # Delete the files
                FileUtils.rm_rf("#{path}/") if path

                raise ActiveRecord::Rollback
            end
        end

        if response[:pass] && path && file
            FrameCenter.delay.import params, path, output_path, file, user
        end

        response

    end

    def self.import params, path, output_path, file, user

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
            process_type: "Frame Center Import (#{params[:project]})",
            filename: File.basename(file),
            creator: user
        )

        # Set the project
        project = params[:project]

        current_time = Time.now
        # Stores variables for the job process
        process_success = false
        error_message = "Something went wrong. Contact Programming"

        # rejections and skips
        duplicate = 0
        skipped = 0
        sun_angle_rejections = 0
        rejected_footprints = 0

        # nri = false
        # sl = false

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Validate the filename
                arr = params[:file].original_filename.split("_")

                # Check to make sure the filename flight date matches the form flight date
                file_date = Date.parse(arr[0])
                if file_date != Date.parse(params[:flight_date])
                    raise Exception, "Filename flight date does not match Form Flight Date"
                end

                # Check if the second array element is a company
                company = Company.find_by(alias: arr[1])
                if company.nil? || company.id != params[:flown_by_id].to_i
                    if company.nil? 
                        raise Exception, "Contractor #{arr[1]} does not exist in application"
                    elsif company.id != params[:flown_by_id].to_i
                        raise Exception, "Contractor #{arr[1]} does not match specified Flown By Company in Form"
                    end
                end

                # Make sure the camera exists
                camera = Camera.find_by(id: params[:camera_id])
                if camera.nil? || (camera.name.downcase != arr[2].downcase)
                    raise Exception, "Camera name does not match the Filename"
                end

                # Check if the third element is a utm zone
                filename_utm_zone = Utm.find_by(zone: arr[3].tr("z", ""))
                if filename_utm_zone.nil?
                    raise Exception, "UTM Zone #{arr[3]} is not a valid UTM Zone"
                end

                # set the state
                # state = State.find(params[:state_id])

                # Create a new History record
                history = History.new
                history.action_type = "Frame Center Upload (#{project})"
                history.creator = user
                history.save

                # Copy the file to the server
                # Get the folder name by converting the current time to seconds
                folder = Time.now.to_i

                # Create a new Upload instance
                upload = Upload.create(
                    uploader: user,
                    folder_path: "#{path}/",
                    upload_type: "FrameCenter",
                )

                out_factory = RGeo::Geographic.spherical_factory(srid: 4326, proj4: '+proj=longlat +datum=WGS84 +no_defs' )

                # Get the state, if no state then it should be nil
                state = nil
                if project == "NAIP"
                    state = State.find_by(id: params[:state_id])
                end

                File.open(file, "r", row_sep: :auto) do |f|
                    f.each_line do |line|

                        # p line

                        if line.length > 5

                            arr = line.split(' ')

                            if arr.size != 11
                                raise Exception, "Row malformation found in txt file, please check the file for errors"
                            end

                            # Get the strip frame and check if it has ".tif" in it
                            strip_frame = arr[1].include?(".tif") ? arr[1].gsub(".tif", "") : arr[1]

                            p strip_frame

                            obj = {
                                project: project,
                                strip: arr[0],
                                strip_frame: strip_frame,
                                gpstime: arr[2],
                                x: arr[3],
                                y: arr[4],
                                z: arr[5],
                                omega: arr[6],
                                phi: arr[7],
                                kappa: arr[8],
                                upload: upload,
                                nri: false,
                                sl: false,
                                naip: project == "NAIP" ? true : false,
                                camera_name: camera.name,
                                flown_by: company,
                                flown_by_alias: company.alias,
                                flown_by_name: company.name,
                                camera: camera,
                                # utm_zone: "#{utm_zone.zone}N",
                                # utm: utm_zone
                            }

                            # Rails.logger.error "LOG - Strip Frame: #{strip_frame}"

                            # Calculate the Latitude and longitude for geometry
                            obj[:latitude] = arr[9]
                            obj[:longitude] = arr[10]
                            obj[:geom] = RGeo::Geographic.spherical_factory(srid: 4326).point(arr[10], arr[9])

                            # Get the latitude and longitude
                            latitude = obj[:latitude].to_f
                            longitude = obj[:longitude].to_f

                            # Calcualte the GPS Time
                            # => Get the Sunday of the week the flight date starts on
                            # => Add the GPS Time to it as seconds
                            obj[:flight_date] = DateTime.parse(params[:flight_date]).beginning_of_week(:sunday) + obj[:gpstime].to_f.seconds

                            # Make sure the Flight Date matches the Calculated GPS Time
                            if obj[:flight_date].strftime("%F") != params[:flight_date]
                                raise Exception, "Frame Center's (Strip Frame: #{obj[:strip_frame]}) GPS Time (#{obj[:flight_date]}} does not match the provided Flight Date (#{params[:flight_date]})!"
                            end

                            # # Get the sun angle 
                            elevation, azimuth = Solar.position(obj[:flight_date], longitude, latitude)
                            obj[:sun_angle] = elevation

                            sun_angle_passed = true
                            if obj[:sun_angle] < Rails.application.secrets.min_sun_angle
                                p "#{strip_frame} - Sun Angle below #{Rails.application.secrets.min_sun_angle}: #{obj[:sun_angle]}"

                                obj[:notes] = "Sun Angle below #{Rails.application.secrets.min_sun_angle}"
                                obj[:sun_angle_error] = true
                                sun_angle_rejections += 1
                                sun_angle_passed = false
                            end

                            if FrameCenter.where(latitude: latitude.round(6), longitude: longitude.round(6), strip_frame: obj[:strip_frame], flight_date: obj[:flight_date], flown_by_id: params[:flown_by_id], camera_id: camera.id).count > 0
                                # Skip to the next record if matched since it already exists
                                # duplicate << obj[:strip_frame]
                                duplicate += 1
                                next
                                # raise Exception, "Existing Frame Center (Strip Frame: #{obj[:strip_frame]}) found with matched Latitude, Longitude, Flight Date, and Strip Frame. Import was terminated."
                            end

                            # Calculate the UTM zone
                            utm = Utm.exclude_geom.find_by("st_contains(utms.geom::geometry, ST_SetSRID(ST_Point(#{longitude}, #{latitude}),4326))")

                            # check if the utm zone matches the filename utm zone
                            if utm.zone != filename_utm_zone.zone
                                raise Exception, "Frame Center #{obj[:strip_frame]} is contained within Zone #{utm.zone}N outside of Zone #{filename_utm_zone.zone}N as specified in the filename"
                            end

                            # Create the record
                            fc = FrameCenter.new(obj)

                            # Query out the matching fooptrint 
                            # => included a spatial query within the 
                            footprint = Footprint.find_by("footprints.project = '#{project}' AND footprints.camera_id = '#{camera.id}' AND footprints.strip_frame = '#{obj[:strip_frame]}' 
                                AND footprints.flight_date = '#{params[:flight_date]}' AND footprints.flown_by_id = '#{company.id}' #{project == "NAIP" ? " AND project_state_id=#{state.id} " : ""}
                                AND st_contains(footprints.geom::geometry, ST_SetSRID(ST_Point(#{fc.longitude}, #{fc.latitude}),4326))")

                            # p "--------"
                            # p "Camera: #{camera.id}"
                            # p "flight_date: #{params[:flight_date]}"
                            # p "strip_frame: #{obj[:strip_frame]}"
                            # p "flown_by_id: #{company.id}"
                            # p fc.strip_frame
                            # p footprint

                            # There should only be 1 footprint that matches the requirement, if not then raise alarm
                            if footprint && footprint.frame_center.nil?

                                # update the project state
                                fc.sl = footprint.sl
                                fc.nri = footprint.nri
                                fc.naip = footprint.naip

                                # nri = true if fc.nri == true
                                # sl = true if fc.sl == true

                                # if the footprint has a county then associate it to the frame center
                                if footprint.county_id.present? || footprint.state_id.present?
                                    fc.county_name = footprint.county_name
                                    fc.state_name = footprint.state_name
                                    fc.county_id = footprint.county_id
                                    fc.state_id = footprint.state_id
                                    # fc.utm_zone = footprint.utm_zone
                                    # fc.utm_id = footprint.utm_id

                                    # get the project state
                                    fc.project_state_id = footprint.project_state_id
                                    fc.project_state_name = footprint.project_state_name
                                end

                                # Update the Frame Centers
                                fc.footprint = footprint
                                fc.plane_id = footprint.plane_id

                                # Update the footprint to include the flight date time
                                footprint.update(flight_date_time: obj[:flight_date])
                                history.footprints << footprint

                                # update the associated tiles (if they don't have AT start/done yet)
                                if project == "NRI/SL" && footprint.tiles.count > 0
                                    tiles = footprint.tiles.flown.asi_accepted.not_at_started.where(flight_date: params[:flight_date])
                                    tiles.each do |tile|
                                        # only update the tile if the associated footprints all have an EO
                                        if tile.footprints.has_flight_date_time.count === tile.footprints.count
                                            history.tiles << tile
                                            tile.update(at_start_date: current_time, at_done_date: current_time)
                                        end
                                    end
                                end

                                # update the associated doqqs (if they don't have AT start/done yet)
                                if project == "NAIP" && footprint.doqqs.count > 0
                                    doqqs = footprint.doqqs.flown.asi_accepted.not_at_started.where(flight_date: params[:flight_date])
                                    if doqqs.count > 0
                                        history.doqqs << doqqs
                                        doqqs.update_all(at_start_date: current_time, at_done_date: current_time)
                                    end
                                end

                            else

                                # Check if the Strip Frame is in the Rejected Footprint
                                # rejected_footprint = RejectedFootprint.find_by(project: project, camera_id: camera.id, strip_frame: obj[:strip_frame], flight_date: params[:flight_date], flown_by_id: company.id)
                                rejected_footprint = RejectedFootprint.find_by("rejected_footprints.project = '#{project}' AND rejected_footprints.camera_id = '#{camera.id}' AND rejected_footprints.strip_frame = '#{obj[:strip_frame]}' AND rejected_footprints.flight_date = '#{params[:flight_date]}' AND rejected_footprints.flown_by_id = '#{company.id}' AND st_contains(rejected_footprints.geom::geometry, ST_SetSRID(ST_Point(#{fc.longitude}, #{fc.latitude}),4326))")

                                if rejected_footprint
                                    # Reject the Frame Center

                                    # Set the footprint id to the original rejected footprint id
                                    fc.footprint_id = rejected_footprint.original_id
                                    fc.plane_id = rejected_footprint.plane_id

                                    # Reject the Fream Center
                                    rejected_frame_center = RejectedFrameCenter.reject fc, "Footprint was already Rejected"
                                    
                                    # If the rejected Frame Center is valid then skip, otherwise raise exception
                                    if rejected_frame_center
                                        upload.rejected_frame_centers << rejected_frame_center
                                        history.rejected_frame_centers << rejected_frame_center
                                        rejected_footprints += 1
                                        next
                                    else
                                        raise Exception, "Error attempting to reject Frame Center #{fc.strip_frame} that matched Rejected Footprint #{rejected_footprint.id}"
                                    end
                                else
                                    # duplicate << obj[:strip_frame]
                                    skipped += 1
                                    next
                                    # raise Exception, "Could not find matching Footprint flown by #{company.alias} using #{camera.name} with Strip Frame #{strip_frame} flown on #{file_date.strftime("%m/%d/%Y")} in Footprints and Rejected Footprints"
                                end
                            end

                            # Save the file
                            if !fc.save
                                raise Exception, "#{strip_frame}:#{fc.errors.full_messages.to_sentence}"
                            end

                        else
                            # Check if removing all spaces leaves an empty string
                            raise Exception, "#{strip_frame}:#{fc.errors.full_messages.to_sentence}" if line.strip.length != 0
                        end

                    end
                end

                p "DONE ITERATING: #{upload.frame_centers.count} Iterated Frame Centers"

                # if upload.frame_centers.count == 0
                #     raise Exception, "No Frame Centers were created, check to make sure valid project is selected."
                # end

                if upload.frame_centers.count > 0 || upload.rejected_frame_centers.count > 0

                    upload.number_uploaded = upload.frame_centers.count + upload.rejected_frame_centers.count
                    upload.save

                    if upload.frame_centers.rejected.count > 0
                        p "PIZZA"
                        # sun_angle_msg = ", #{upload.frame_centers.rejected.count} Frame Centers did not meet the Minimum Sun Angle and were rejected"

                        # Auto reject Frame Centers
                        if project == "NRI/SL"

                            # Check associated fotoprints of invalid frame centers and determine if it's for NRI and/or SL
                            footprint_ids = upload.frame_centers.rejected.pluck(:footprint_id)

                            p "<><><><><><>"
                            p "NRI Reject: #{Footprint.select(:id).where(id: footprint_ids, nri: true).size}"
                            p "SL Reject: #{Footprint.select(:id).where(id: footprint_ids, sl: true).size}"
                            p "<><><><><><>"

                            # Check rejected footprints 
                            if Footprint.select(:id).where(id: footprint_ids, nri: true).size > 0

                                rejection_output = FrameCenter.auto_reject_tiles Date.parse(params[:flight_date]), upload, camera, company, user, "NRI"

                                if !rejection_output[:pass]
                                    raise Exception, rejection_output[:error] ? rejection_output[:error] : "Error occurred while attmepting to auto-reject the Frame Centers. Import aborted."
                                end

                                # Log and send email
                                Mailbox.ship({
                                    users: MailGroup.find_by(name: "Rejection").users | [user],
                                    subject: "#{project} Tiles have been rejected",
                                    message: "#{rejection_output[:message]}<br/><br/>The following NRI Tiles have been rejected during Frame Center Import:<br/><ul>#{rejection_output[:rejected_tiles].map {|rt| "<li><b>#{rt.poly_id}</b> - <i>(Flight Date: #{rt.flight_date.strftime("%m/%d/%Y")}, Flown By: #{rt.flown_by_alias})</i></li>"}.join("")}</ul>".html_safe
                                })

                            elsif Footprint.select(:id).where(id: footprint_ids, sl: true).size > 0

                                rejection_output = FrameCenter.auto_reject_tiles Date.parse(params[:flight_date]), upload, camera, company, user, "SL"

                                if !rejection_output[:pass]
                                    raise Exception, rejection_output[:error] ? rejection_output[:error] : "Error occurred while attmepting to auto-reject the Frame Centers. Import aborted."
                                end

                                # Log and send email
                                Mailbox.ship({
                                    users: MailGroup.find_by(name: "Rejection").users | [user],
                                    subject: "#{project} Tiles have been rejected",
                                    message: "#{rejection_output[:message]}<br/><br/>The following SL Tiles have been rejected during Frame Center Import:<br/><ul>#{rejection_output[:rejected_tiles].map {|rt| "<li><b>#{rt.poly_id}</b> - <i>(Flight Date: #{rt.flight_date.strftime("%m/%d/%Y")}, Flown By: #{rt.flown_by_alias})</i></li>"}.join("")}</ul>".html_safe
                                })

                            end
                                
                        end

                        if project == "NAIP"

                            rejection_output = FrameCenter.auto_reject_doqqs Date.parse(params[:flight_date]), state, upload, camera, company, user

                            if !rejection_output[:pass]
                                raise Exception, rejection_output[:error] ? rejection_output[:error] : "Error occurred while attmepting to auto-reject the Frame Centers. Import aborted."
                            end

                            # Log and send email
                            if rejection_output[:doqqs].count > 0
                                Mailbox.ship({
                                    users: MailGroup.find_by(name: "Rejection").users | [user],
                                    subject: "DOQQs have been rejected",
                                    message: "#{rejection_output[:message]}<br/><br/>The following Doqqs have had their Flight Date cleared:<br/><ul>#{rejection_output[:doqqs].map {|doqq| "<li><b>#{doqq.qq_apfo_name}</b></li>"}.join("")}</ul>".html_safe
                                })
                            end

                        end

                        # Find and update all tiles that have rejected frame centers covering them
                        # FrameCenter.find_tiles_of_rejected_frame_centers

                        # msg = "Uploaded #{upload.frame_centers.count} Frame Centers from file \"#{params[:file].original_filename}\" and marked as AT Started/AT Done #{sun_angle_msg}"
                    end

                    # Response Message
                    # default message
                    message = "Imported #{upload.frame_centers.count} valid Frame Centers"

                    if sun_angle_rejections > 0 || rejected_footprints > 0 || duplicate > 0 || skipped > 0
                        message = "Iterated #{upload.frame_centers.count + upload.rejected_frame_centers.count} total Frame Centers (#{upload.frame_centers.count} were valid imports"
                    end

                    # build the error message
                    sun_angle_rejection_message = ""
                    duplicate_message = ""
                    rejected_footprints_message = ""
                    skipped_message = ""

                    # check sun angle rejection count
                    sun_angle_rejection_message = ", #{sun_angle_rejections.to_s} were rejected due to not meeting the minimum sun angle" if sun_angle_rejections > 0 
                    
                    # check the rejected footprints count
                    rejected_footprints_message = ", #{rejected_footprints.to_s} were rejected and assigned to existing Rejected Footprints" if rejected_footprints > 0 

                    # check the duplicate counts
                    duplicate_message = ", #{duplicate.to_s} duplicates were skipped" if duplicate > 0

                    # check the skipped counts
                    skipped_message = ", #{skipped.to_s} were skipped due to no matching Footprint" if skipped > 0

                    # assemble the final message
                    message = message + sun_angle_rejection_message + rejected_footprints_message + duplicate_message + skipped_message + " for #{project} from \"#{params[:file].original_filename}\"."

                    # ByPass Eo Splitter tool if no valid frame centers
                    if project == "NRI/SL" && upload.frame_centers.count > 0

                        if upload.frame_centers.nri.count > 0
                            # pass the upload to the eo splitter
                            self.eo_splitter "NRI", upload, Rails.application.secrets.nri_eo_splitter_path
                            message = message + " NRI EOs were split to #{Rails.application.secrets.nri_eo_splitter_p_path}."
                        end

                        if upload.frame_centers.sl.count > 0
                            # pass the upload to the eo splitter
                            self.eo_splitter "SL", upload, Rails.application.secrets.sl_eo_splitter_path
                            message = message + " SL EOs were split to #{Rails.application.secrets.sl_eo_splitter_p_path}."
                        end

                        # Iterate the tiles and update the median flight date time
                        # => expanded this to incude all tiles that match the criteria since they might not have been completely covered the first time
                        Tile.flown.at_done.not_shipped.where(flight_date: params[:flight_date], flown_by: company, camera: camera).each do |tile|
                            tile.generate_median_flight_date_time
                        end
                    end

                    if project == "NAIP"
                        # Iterate the Doqqs and update the median flight date time
                        history.doqqs.each do |doqq|
                            doqq.generate_median_flight_date_time
                        end
                    end

                    # Create a new History record
                    history.message = message
                    history.save

                    # add records to polymorphic association
                    history.uploads << upload
                    history.frame_centers = upload.frame_centers

                    job.update(
                        finished_at: Time.now,
                        active: false,
                        success: true,
                        upload: upload,
                        message: message
                    )

                    # Log and send email
                    Mailbox.ship({
                        users: MailGroup.find_by(name: "AT Done").users | [user],
                        subject: "#{project} Frame Centers have been imported",
                        message: message,
                        route: Rails.application.routes.url_helpers.show_timeline_url(history.id, only_path: false, host: Rails.application.secrets.host)  
                    })

                    # Update the process
                    process_success = true

                else
                    raise Exception, "No Frame Centers were created during import process"
                end

            rescue Exception => exception
                Rails.logger.error "Frame Center Import Error: #{exception.message}"
                error_message = exception.message

                p "-----------"
                p exception.backtrace.count
                exception.backtrace.each do |x|
                    next if !x.include? "frame_center.rb"
                    x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
                   p [$1,$2,$4]
                end
                p "-----------"

                # # Delete the Upload and History
                # upload.destroy if upload.present?
                # history.destroy if history.present?

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
                subject: "#{project} Frame Center Import Failed",
                message: "Frame Center Import Failed, error encountered is listed below: <br/><br/>#{error_message}".html_safe
            })

            # Send email to notified it failed
            # PostmasterMailer.notify(user, "Frame Center Import Failed, error encountered is listed below: <br/><br/>#{error_message}".html_safe, "USDA #{Rails.application.secrets.project_year}: Frame Center Import Failed - #{Time.now.strftime("%m/%d/%Y")}").deliver

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

    end

    def self.eo_splitter project, upload, output_path=Rails.application.secrets.eo_splitter_path
        # Iterate the EOs and write to folders based on the state and utm zone
        p "eo_splitter #{output_path}"

        # Iterate the uploaded Frame Centers
        # Get the Footprint and iterate the easements
        # Build an array of frame centers in each UTM and State
        # Iterate and write the EOs to each file by State and UTM

        # if no frame centers then throw error
        raise Exception, "No Frame Center in Upload" if upload.frame_centers.size == 0

        fc_obj = {}
        
        if project == "NRI"
            fc_obj[:nri] = true
        elsif project == "SL"
            fc_obj[:sl] = true
        end

        # object to build the renders
        obj = {
            no_footprint: [],
            states: {}
        }

        # p "-----"
        # p fc_obj
        # p upload.frame_centers.has_footprint.pluck(:nri).uniq
        # p upload.frame_centers.has_footprint.pluck(:sl).uniq
        # p upload.frame_centers.has_footprint.where(fc_obj).count
        # p "-----"

        # capture the first frame center to 
        first = upload.frame_centers.where(fc_obj).first

        # Add the folder to the output path
        output_path = "#{output_path}/EO Split #{first.flight_date.strftime("%F")}"

        # make the folder in the directory
        FileUtils.mkdir_p(output_path) unless File.directory?(output_path)

        # build a folder form the current 
        current_time_folder_name = Time.now().strftime("%Y-%m-%d_%H-%M-%S")

        # Add the folder to the output path
        output_path = "#{output_path}/#{current_time_folder_name}"

        # make the folder in the directory
        FileUtils.mkdir_p(output_path) unless File.directory?(output_path)

        # iterate the frame centers
        # FrameCenter.includes(footprint: [:tiles]).
        #     where(project: first.project, flight_date: first.flight_date.all_day, camera_id: first.camera_id, flown_by_id: first.flown_by_id)
        #         .order(:strip).each do |fc|

        upload.frame_centers.where(fc_obj).includes(footprint: [:tiles]).order(:strip).each do |fc|

            # if no Footprint then add to the array
            if fc.footprint.nil?
                obj[:no_footprint] << fc
                return
            end

            # iterate the easements
            fc.footprint.tiles.where(project: project).includes(:easement).each do |tile|

                # get the easement of the tile
                easement = tile.easement

                # Create the state object if it doesn't exist
                obj[:states][easement.state_abv] = {strip_frames: [], zone: [], text: "", rejected: ""} if obj[:states][easement.state_abv].nil?

                # skip if the frame center has already been assigned to this UTM Zome or not
                next if obj[:states][easement.state_abv][:strip_frames].include? fc.strip_frame

                # Add the strip frame to the array to track it's been processed
                obj[:states][easement.state_abv][:strip_frames] << fc.strip_frame

                # # convert the coordinates into the utm zone of the easement
                # sql = "SELECT ST_X(ST_Transform(geom::geometry, 269#{easement.utm.zone})) AS x, 
                #                 ST_Y(ST_Transform(geom::geometry, 269#{easement.utm.zone})) AS y 
                #                     FROM frame_centers where id = #{fc.id}"

                # result = ActiveRecord::Base.connection.execute(sql)

                # # get the x and y value
                # x = result[0]["x"]
                # y = result[0]["y"]

                obj[:states][easement.state_abv][:zone] |= [tile.utm_zone]

                # format the values
                gpstime = sprintf("%.5f", fc.gpstime)
                x = sprintf("%.3f", fc.x)
                y = sprintf("%.3f", fc.y)
                z = sprintf("%.3f", fc.z)
                omega = fc.omega < 0 ? sprintf("%.5f", fc.omega) : " #{sprintf("%.5f", fc.omega)}"
                phi = fc.phi < 0 ? sprintf("%.5f", fc.phi) : " #{sprintf("%.5f", fc.phi)}"

                kappa = sprintf("%.5f", fc.kappa)
                kappa = "#{" " * (10 - kappa.length)}#{kappa}"

                latitude = sprintf("%.8f", fc.latitude)
                longitude = sprintf("%.8f", fc.longitude)

                # Check if the frame center is rejected and if so add to the rejected eo otherwise add it to the valid text
                if fc.sun_angle_error
                    obj[:states][easement.state_abv][:rejected] += 
                        "#{fc.strip}  #{fc.strip_frame} #{gpstime} #{x} #{y} #{z}   #{omega}   #{phi} #{kappa} #{latitude} #{longitude}\n"
                else
                    obj[:states][easement.state_abv][:text] += 
                        "#{fc.strip}  #{fc.strip_frame} #{gpstime} #{x} #{y} #{z}   #{omega}   #{phi} #{kappa} #{latitude} #{longitude}\n"
                end

            end

        end

        # pp obj

        # Build outputs
        # List Rejected EOs
        # List EOs that have no Footprints associated
        # Build folders for each State and UTM Zone

        obj[:states].each do |state, obj|

            if obj[:rejected].present?

                # Create rejection folder if it doesn't exist
                FileUtils.mkdir_p("#{output_path}/other") unless File.directory?("#{output_path}/other")

                # build the filename
                filename = "#{first.flight_date.strftime("%Y%m%d")}_#{first.flown_by_alias}_#{first.camera_name}_#{state}_#{obj[:zone].join("_")}_REJECTED_EO.txt"

                html = "THESE STRIP FRAMES HAVE BEEN MARKED AS REJECTED IN THE SYSTEM DUE TO SUN ANGLE. DO NOT USE UNLESS THE USDA GRANTS US AN EXCEPTION.\n\n\n"
                html += obj[:rejected]

                # create file and 
                File.open("#{output_path}/other/#{filename}", "w") {|file| file.puts html }

            end

            if obj[:text].present?

                # build the filename
                filename = "#{first.flight_date.strftime("%Y%m%d")}_#{first.flown_by_alias}_#{first.camera_name}_#{state}_#{obj[:zone].join("_")}_EO.txt"

                # Create the state folder if it doesn't exist
                # FileUtils.mkdir_p("#{output_path}/#{state}") unless File.directory?("#{output_path}/#{state}")

                # # Create the utm folder if it doesn't exist
                # FileUtils.mkdir_p("#{output_path}/#{state}/#{utm}") unless File.directory?("#{output_path}/#{state}/#{utm}")

                # create file and 
                # File.open("#{output_path}/#{state}/#{utm}/#{filename}", "w") {|file| file.puts obj[:text] }
                File.open("#{output_path}/#{filename}", "w") {|file| file.puts obj[:text] }

            end
        end

        "done"

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

                fc_reject_obj = {
                    flight_date: flight_date.all_day, 
                    camera: camera, 
                    flown_by: flown_by
                }

                if project == "NRI"
                    fc_reject_obj[:nri] = true
                elsif project == "SL"
                    fc_reject_obj[:sl] = true
                end


                frame_centers_to_reject = upload.frame_centers.rejected.where(fc_reject_obj)

                # Get the Rejected Footprints that have associated frame centers that match flight date, state, camera, and company
                footprints = frame_centers_to_reject.map {|fc| fc.footprint}

                # Create new history object to store all rejections
                history = History.new
                history.action_type = "Auto-Reject Tiles"
                history.creator = user
                history.save

                p "---------"
                p "upload: #{upload.id}"
                p "frame_centers_to_reject: #{frame_centers_to_reject.pluck(:strip_frame)}"
                p "total frame_centers: #{upload.frame_centers.count}"
                p "footprints count: #{footprints.count}"
                p "---------"

                footprints.each do |footprint|

                    # Check the footprint is SL only
                    if footprint.project == "NAIP"
                        raise Exception, "Footprint: #{footprint.id} is marked as NAIP, not SL. Cannot reject" 
                    end

                    frame_center = footprint.frame_center

                    # Reject the Footprint and return the new rejected_footprint
                    rejected_footprint = RejectedFootprint.reject footprint, message

                    if !rejected_footprint
                        raise Exception, "Footprint: #{footprint.id} could not be rejected!"
                    end

                    # Reject the associated Frame Center
                    rejected_frame_center = RejectedFrameCenter.reject frame_center, message

                    if !rejected_frame_center
                        raise Exception, "Frame Center (StripFrame: #{frame_center.strip_frame}) could not be rejected!"
                    end

                    # Add rejected footprint and rejected frame centers to history
                    history.rejected_footprints << rejected_footprint
                    history.rejected_frame_centers << rejected_frame_center

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

                DissolvedFootprint.find_or_create_by(name: "frame_centers").update(geom: nil)

                # Dissolve all the footprints 
                sql = "UPDATE dissolved_footprints SET geom = (SELECT ST_Multi(st_union(ST_Multi(geom::geometry))) AS the_geom from footprints where ST_IsValid(geom::geometry)
                    AND footprints.id IN (#{footprint_ids.uniq.join(", ")}) ) WHERE name='frame_centers'"
                ActiveRecord::Base.connection.execute(sql)

                # select out easements that aren't contained within the dissolved layer
                easements = Easement.flown.includes(:tiles).joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='frame_centers' 
                    AND not st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").where(
                        project: project, flight_date: flight_date, tiles: {camera: camera, flown_by: flown_by}
                    )

                p "-----------"
                p "EASEMENTS: #{easements.count}"
                p "-----------"

                # Reject the Tiles and associated footprints/frame centers
                output, history = Rejection.reject_tiles easements.pluck(:poly_id), flight_date, history, false, message

                # set the message for history
                history.message = "Auto-Rejected #{history.rejected_tiles.count} Tiles, #{history.rejected_footprints.count} Footprints, and #{history.rejected_frame_centers.count} Frame Centers"
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

    def self.auto_reject_doqqs flight_date, state, upload, camera, flown_by, user
        # Dissolves all the NAIP Footprints into a single feature
        # Check if any Doqqs marked as flown are now not completely covered
        # If not then send an email about them not being flown


        # Start a Transaction Block
        ActiveRecord::Base.transaction(joinable: false, requires_new: true) do
            begin

                frame_centers_to_reject = FrameCenter.rejected.where(project: "NAIP", project_state_id: state.id, upload: upload, flight_date: flight_date.all_day, camera: camera, flown_by: flown_by)

                # Get the Rejected Footprints that have associated frame centers that match flight date, camera, and company
                footprints = frame_centers_to_reject.map {|fc| fc.footprint}

                # Create new history object to store all rejections
                history = History.new
                history.action_type = "Auto-Reject Doqqs"
                history.creator = user
                history.save

                footprints.each do |footprint|

                    # Check the footprint is SL only
                    if footprint.project == "SL" || footprint.project == "NRI" 
                        raise Exception, "Footprint: #{footprint.id} is marked as SL, not NAIP. Cannot reject"
                    end

                    frame_center = footprint.frame_center

                    # Reject the Footprint and return the new rejected_footprint
                    rejected_footprint = RejectedFootprint.reject footprint

                    if !rejected_footprint
                        raise Exception, "Footprint: #{footprint.id} could not be rejected!"
                    end

                    # Reject the associated Frame Center
                    rejected_frame_center = RejectedFrameCenter.reject frame_center

                    if !rejected_frame_center
                        raise Exception, "Frame Center (StripFrame: #{frame_center.strip_frame}) could not be rejected!"
                    end

                    # Add rejected footprint and rejected frame centers to history
                    history.rejected_footprints << rejected_footprint
                    history.rejected_frame_centers << rejected_frame_center

                end

                # Grab all naip footprints ids
                ids = Footprint.naip.select(:id).pluck(:id)

                # Dissolve the footprints
                DissolvedFootprint.footprints ids, "NAIP"

                # Query out flown doqqs that are not completely contained by the footprints 
                # => This means the Doqq is no longer completely covered, therefore it is no longer flown
                doqqs = Doqq.flown.where(project_state_id: state.id).joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='footprints' 
                    AND NOT st_contains(dissolved_footprints.geom::geometry, doqqs.geom::geometry)")

                doqqs.each do |doqq|
                    # Clear the flight date since that is no longer valid
                    doqq.update(flight_date: nil, median_flight_date_time: nil, vector_metadatum_id: nil)

                    # Push the doqq to the history
                    history.doqqs << doqq
                end

                if history.doqqs.count > 0
                    # set the message for history
                    history.message = "Auto-Rejected #{history.rejected_tiles.count} Tiles, #{history.rejected_footprints.count} Footprints, and #{history.rejected_frame_centers.count} Frame Centers"
                    history.save
                    return {
                        pass: true,
                        message: history.message,
                        doqqs: history.doqqs
                    }
                else
                    history.destroy
                    return {
                        pass: true,
                        mesage: "No Doqqs rejected",
                        doqqs: []
                    }
                end

        rescue => exception
            # p except
            Rails.logger.error "Frame Center Auto Reject Doqq Error: #{exception.message}"
            ActiveRecord::Rollback
            return {
                pass: false,
                error: exception.message
            }
        end
    end

    end

    # Pass the selected frame centers as argument
    def self.frame_centers_with_sun_angle_errors params
        p "======="
        p params
        p "======="

        flight_date = Date.parse(params[:flight_date])

        # Copy the file to the server
        # Get the folder name by converting the current time to seconds
        folder = Time.now.to_i

        path = "#{Rails.root}/assets/frame_centers_with_sun_angle_errors/#{folder}"

        records = []
        
        # Get the Footprints that have associated frame center
        fp_ids = FrameCenter.rejected.where(state_id: params[:state], flight_date: flight_date.all_day).map {|fc| fc.footprint.id}

        # Get all footprints that were flown on that flight date
        footprints = Footprint.where(flight_date: flight_date, state_id: params[:state]).where.not(id: fp_ids)

        p "----"
        p footprints.pluck(:id)
        p "----"

        if footprints.count == 0
            return {
                pass: false,
                message: "No Rejected Frame Centers found on selected Flight Date and within State"
            }
        end

        # Dissolve all the footprints 
        sql = "UPDATE dissolved_footprints SET geom = (SELECT st_union(geom::geometry) AS the_geom 
            from footprints where ST_IsValid(geom::geometry) AND footprints.id IN (#{footprints.pluck(:id).join(", ")})
            AND footprints.flight_date = '#{flight_date.strftime("%F")}' ) WHERE name='all'"

        ActiveRecord::Base.connection.execute(sql)

        # select out easements that aren't contained within the dissolved layer
        records = Easement.flown.joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='all' AND NOT st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").where(flight_date: flight_date)

        if records.count == 0
            return {
                pass: false,
                message: "No Rejected Frame Centers found on selected Flight Date and within State"
            }
        end

        # Create a folder if it doesn't exist
        FileUtils.mkdir_p(path) unless File.directory?(path)

        file_name = "frame_centers_with_sun_angle_error_on_flight_date_#{flight_date.strftime("%Y-%m-%d")}_#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.txt"

        output = {
            pass: true,
            file: "#{path}/#{file_name}",
            file_name: file_name
        }

        # Open the file and write out the records
        File.open(output[:file], "w+") do |f|
            records.each do |record|
                f.puts record.poly_id
            end
        end

        # Create a new History record
        history = History.new
        history.action_type = "Frame Centers with Sun Angle Errors"
        history.url = "#{path}/#{file_name}"
        history.creator = params[:user]
        history.save

        history.easements << records

        output
    end

    def self.find_tiles_of_rejected_frame_centers

        Tile.where(review_desc: "Tiles that are marked as Flown but overlapping Frame Centers are Rejected").update(review_desc: nil)

        if DissolvedFootprint.find_by(name: "rejection").nil?
            DissolvedFootprint.create(name: "rejection")
        end

        # Get all the rejected Frame Centers and select Tiles
        # Dissolve the footprints into a single layer where the points are contained within
        sql = "UPDATE dissolved_footprints SET geom = (SELECT st_multi(st_union(fp.geom::geometry)) from footprints fp, frame_centers fc WHERE fc.sun_angle_error = FALSE AND st_within(fc.geom::geometry, fp.geom::geometry)) WHERE name='rejection'"
        results = ActiveRecord::Base.connection.execute(sql)

        # Intersect the Footprints with the Tiles
        # => Update the tiles to mark as at start/done
        Easement.includes(:tiles).flown.joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='rejection' AND st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").each do |easement|
            easement.tiles.update(review_desc: "Tiles that are marked as Flown but overlapping Frame Centers are Rejected")
        end
    end

    def self.find_county_state_utm

        FrameCenter.where(county_id: nil).each do |fc|
            county = County.includes(:state).find_by("st_contains(counties.geom::geometry, ST_SetSRID(ST_Point(#{fc.longitude}, #{fc.latitude}),4326))")
            if county
                p fc.id
                fc.update(
                    county_name: county.name,
                    state_name: county.state.name,
                    county: county,
                    state: county.state
                )
            end
        end

    end

    def self.test_contains_footprint

        errors = []

        FrameCenter.all.order(:id).each do |fc|

            p fc.id

            if !Footprint.find_by("st_contains(footprints.geom::geometry, ST_SetSRID(ST_Point(#{fc.longitude}, #{fc.latitude}),4326)) and footprints.id = #{fc.footprint_id}")
                errors << fc.id
            end

        end

        p errors

    end

    def self.find_no_associated_footprints
        none = []
        rejected = []
    
        FrameCenter.includes(:footprint).all.each do |fc|
            if RejectedFootprint.where(original_id: fc.footprint_id).count > 0
                rejected << fc.id

                # # Reject the Fream Center
                rejected_frame_center = RejectedFrameCenter.reject fc

                next
            end
            
            none << fc if fc.footprint.nil?

        end

        p "done, matched #{rejected.count} frame centers to rejected tiles and found #{none.count} existing footprints"
    end

end
