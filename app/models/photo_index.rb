class PhotoIndex < ApplicationRecord
    include Concerns::Archive
    include Rails.application.routes.url_helpers

    # Associations
    belongs_to :upload
    belongs_to :camera
    belongs_to :footprint, optional: true
    belongs_to :rejected_footprint, optional: true
    belongs_to :flown_by, class_name: 'Company'
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs

    # Validations
    validates :strip, :frame, :strip_frame, :flown_by_name, :camera_name, :flight_date, :flight_date_time, :gpstime, :sun_angle, :latitude, :longitude, :geom, presence: true
    validates :footprint_id, :rejected_footprint_id, uniqueness: true, allow_nil: true

    # Scopes
    scope :sl,                      -> { where(project: "SL") }
    scope :naip,                    -> { where(project: "NAIP") }
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

                # Check the project
                raise Exception, "No Project Argument found" if params[:project].blank? || (!Rails.application.secrets.active_projects.include? params[:project])

                # Validate the filename
                arr = params[:file].original_filename.split("_")

                # Check if the second array element is a company
                company = Company.find_by(alias: arr[1])
                if company.nil? || company.id != params[:flown_by_id].to_i
                    if company.nil? 
                        raise Exception, "Contractor #{arr[1]} does not exist in application"
                    elsif company.id != params[:flown_by_id].to_i
                        raise Exception, "Contractor #{arr[1]} does not match specified Flown By Company in Form"
                    end
                end

                # Check the Camera
                camera = Camera.find_by(id: params[:camera_id])
                camera_filename = Camera.find_by(name: arr[2])
                if camera.id != camera_filename.id
                    raise Exception, "Camera extract from Filename does not match the Camera supplied by the form"
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

        p "Imported"

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

        current_time = Time.now
        # Stores variables for the job process
        process_success = false
        error_message = "Something went wrong. Contact Programming"

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Validate the filename
                arr = params[:file].original_filename.split("_")

                # Check if the second array element is a company
                company = Company.find_by(alias: arr[1])
                if company.nil? || company.id != params[:flown_by_id].to_i
                    if company.nil? 
                        raise Exception, "Contractor #{arr[1]} does not exist in application"
                    elsif company.id != params[:flown_by_id].to_i
                        raise Exception, "Contractor #{arr[1]} does not match specified Flown By Company in Form"
                    end
                end

                # Check the Camera
                camera = Camera.find_by(id: params[:camera_id])
                camera_filename = Camera.find_by(name: arr[2])
                if camera.id != camera_filename.id
                    raise Exception, "Camera extract from Filename does not match the Camera supplied by the form"
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

                File.open(file, "r") do |f|
                    f.each_line do |line|

                        # Remove the newlines from end of line
                        line = line.tr("\r\n","")

                        # split the array by commans
                        arr = line.split(" ")

                        # extract the strip and frame from the strip_frame
                        strip, frame = arr[1].split("_")

                        # p "======"
                        # p "gpstime: #{arr[0]}"
                        # p "strip: #{strip}"
                        # p "frame: #{frame}"
                        # p "strip_frame: #{arr[1]}"
                        # p "flight_time: #{Date.strptime(arr[2], "%m/%d/%Y")}"
                        # p "latitude: #{arr[3]}"
                        # p "longitude: #{arr[4]}"

                        # if the line is not 7 indices then throw error
                        if arr.size != 5
                            raise Exception, "Row malformation found in txt file, please check the file for errors"
                        end
                        
                        next if arr[1] == "Free shot"

                        # Check for duplicate photo indexes
                        if PhotoIndex.where(
                                strip_frame: arr[1], 
                                latitude: arr[3].to_f.round(6), 
                                longitude: arr[4].to_f.round(6), 
                                flight_date: Date.strptime(arr[2], "%m/%d/%Y"), 
                                gpstime: arr[0],
                                flown_by: company, 
                                camera: camera
                            ).count > 0
                            p "Found duplicate strip frame: #{strip}_#{frame}. Skipping"
                            next
                        end

                        # start building the PhotoIndex
                        record = PhotoIndex.new(
                            project: params[:project],
                            strip: strip,
                            frame: frame,
                            strip_frame: arr[1],
                            flown_by_name: company.alias,
                            camera_name: camera.name,
                            flight_date: Date.strptime(arr[2], "%m/%d/%Y"),
                            gpstime: arr[0],
                            recorded_sun_angle: nil,
                            latitude: arr[3].to_f, 
                            longitude: arr[4].to_f,
                            geom: RGeo::Geographic.spherical_factory(srid: 4326).point(arr[4].to_f, arr[3].to_f),
                            camera: camera,
                            upload: upload,
                            flown_by: company
                        )

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
                            record.sun_angle_error = true
                        end

                        # save the record
                        record.save!

                        # Query out the matching fooptrint 
                        # => included a spatial query within the 
                        footprint = Footprint.find_by("footprints.project = '#{project}' AND footprints.camera_id = '#{camera.id}' AND footprints.strip_frame = '#{record.strip_frame}' AND footprints.flight_date = '#{record.flight_date.strftime("%F")}' AND footprints.flown_by_id = '#{company.id}' AND st_contains(footprints.geom::geometry, ST_SetSRID(ST_Point(#{record.longitude}, #{record.latitude}),4326))")

                        if footprint

                            # update attributes
                            record.county_name = footprint.county_name
                            record.state_name = footprint.state_name
                            record.utm_zone = footprint.utm_zone

                            record.county_id = footprint.county_id
                            record.state_id = footprint.state_id
                            record.utm_id = footprint.utm_id
                            record.footprint = footprint
                            record.save!

                            # add the foorptint to the appropriate array
                            valid_footprints << footprint if !record.sun_angle_error
                            footprints_to_be_rejected << footprint if record.sun_angle_error
                        else
                            # query the county and UTM zone
                            sql = "select id, zone from utms u where st_intersects(ST_GeomFromText('#{record.geom.to_s}'), u.geom)"
                            result = ActiveRecord::Base.connection.execute(sql)

                            record.utm_id = result[0]["id"]
                            record.utm_zone = "#{result[0]["zone"]}N"

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

                            # Update the notes and save
                            record.notes = "No Footprint Found"
                            record.save!
                        end

                        history.photo_indices << record
                    end
                end

                # check if there were any 
                if valid_footprints.size == 0
                    raise Exception, "No Footprints were associated with Photo Indices. Upload aborted."
                end

                p "FOOTPRINTS TO BE REJECTED: #{footprints_to_be_rejected.pluck(:id)}"
                # check the footprints that need to be rejected
                if footprints_to_be_rejected.size > 0
                    PhotoIndex.auto_reject_tiles footprints_to_be_rejected, user

                    # Find and update photo indices so they point to rejected footprints
                    upload.photo_indices.each do |pi|
                        # p "#{pi.strip_frame} | #{pi.footprint_id}"

                        # Find the rejected footprint and return the id
                        rejected_footprint = RejectedFootprint.select(:id).find_by(original_id: pi.footprint_id)

                        # if the rejected footprint exists then update the photo index file to point to it
                        if rejected_footprint.present?
                            pi.update(footprint_id: nil, rejected_footprint_id: rejected_footprint.id)
                        end
                    end
                end

                job.update(
                    finished_at: Time.now,
                    active: false,
                    success: true,
                    upload: upload,
                    message: "Photo Index Import completed Successfully"
                )

                message = "Successfully imported #{history.photo_indices.count} Photo Indices from #{params[:file].original_filename}. #{history.photo_indices.approved.count} contained valid sun angles."

                if history.photo_indices.rejected.count > 0
                    message += " #{history.photo_indices.rejected.count} did not meet the sun angle requirement."
                end

                if history.photo_indices.where(footprint_id: nil, rejected_footprint_id: nil).count > 0
                    message += " #{history.photo_indices.where(footprint_id: nil, rejected_footprint_id: nil).count} Photo Indices did not associate to a Footprint."
                end

                # Update the history
                history.update(message: message)
                history.uploads << upload

                # Build the Export of Photo ID
                PhotoIndex.build_export_file upload

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

    # def self.list_rejected_strip_frames history
    #     output = []

    #     p history.rejected_footprints.count

    #     history.rejected_footprints.includes(:historic_assocs).each do |rfp|
    #         pi = rfp.photo_index

    #         if pi.nil?
    #             output << "#{rfp.strip_frame} | #{rfp.flight_date}"
    #         else
    #             output << "#{rfp.strip_frame} | #{rfp.flight_date.strftime("%F")} | #{pi.sun_angle.to_f}"
    #         end
    #     end

    #     # Upload.where(id: [1192, 1193]).each do |upload|     
    #     #     # upload.history.rejected_footprints.each do |rfp|
    #     #     #     pi = rfp.photo_index

    #     #     #     if pi.nil?
    #     #     #         output << "#{rfp.strip_frame} | #{rfp.flight_date}"
    #     #     #     else
    #     #     #         output << "#{rfp.strip_frame} | #{rfp.flight_date.strftime("%F")} | #{pi.sun_angle.tof_f.to_s}"
    #     #     #     end
    #     #     # end
    #     # end

    #     p output
    # end

    def self.auto_reject_tiles footprints, user=User.first

        # find the tiles of the associated footprints
        # reject the tiles
        # check if any of the rejected footprints are still existing and reject those too

        # Create new history object to store all rejections
        history = History.new
        history.action_type = "Photo Index Auto-Reject Tiles"
        history.creator = user
        history.save

        tiles_to_review = {}

        p "photo index auto reject tiles"
        # p "#{footprints}"
        p "----------------"

        footprints.each do |footprint|

            # Check the footprint is SL only
            if footprint.project == "NAIP"
                raise Exception, "Footprint: #{footprint.id} is marked as NAIP, not SL. Cannot reject" 
            end

            # Create a new array scoped based on the flight date
            tiles_to_review[footprint.flight_date.strftime("%F")] = [] if tiles_to_review[footprint.flight_date.strftime("%F")].nil?

            # pull the associated tiles out to check if they should be rejected
            tiles_to_review[footprint.flight_date.strftime("%F")] |= Tile.select(:poly_id).where(id: TileFootprint.where(footprint_id: footprint.id).pluck(:tile_id)).pluck(:poly_id)
        end

        # Check to make sure all the footprints were rejected
        # => if there is any orphaned footprints they will not get collected by the tile rejection process
        Footprint.where(id: footprints.pluck(:id)).each do |footprint|
            p footprint.id

            # get the frame center before deleting the footprint
            framecenter = footprint.frame_center

            # Reject the Footprint and return the new rejected_footprint
            rejected_footprint = RejectedFootprint.reject footprint

            if !rejected_footprint
                raise Exception, "Footprint: #{footprint.id} could not be rejected!"
            end

            # Reject the associated Frame Center of the footprint
            if framecenter
                rejected_frame_center = RejectedFrameCenter.reject framecenter, "Rejection during Photo Index upload"

                if !rejected_frame_center
                    # raise "Frame Center #{fc.id} could not be rejected!"
                    # raise ActiveRecord::Rollback
                    raise Exception, "Frame Center #{fc.id} could not be rejected!"
                end

                history.rejected_frame_centers << rejected_frame_center
            end

            history.rejected_footprints << rejected_footprint
        end
        
        p "++++++++++++"
        p "Remaining footprints: #{Footprint.where(id: footprints.pluck(:id)).count}"

        p "TILES: #{tiles_to_review}"

        tiles_to_review.each do |key, poly_ids|
            # p key

            tiles_to_reject = []

            # iterate the array
            poly_ids.each do |poly_id|

                tile = Tile.includes(:footprints).find_by(poly_id: poly_id)
                p "Footprints: #{tile.footprints.pluck(:id)}"

                # check if there are any footprints
                # => if not then add to the tiles_to_reject
                if tile.footprints.count == 0
                    tiles_to_reject << poly_id
                    next
                end

                # Dissolve the associated footprints
                DissolvedFootprint.footprints tile.footprints.pluck(:id), "SL" 

                # check if compeltely covered
                easement_to_reject = Easement.flown.includes(:tiles).joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='footprints' 
                    AND not st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").where(
                        project: "SL", poly_id: poly_id
                    ).group_by(&:flight_date)

                # if the easement is found then mark it to be rejected
                tiles_to_reject << poly_id if easement_to_reject.count == 1
            
            end

            p "REJECTING: #{tiles_to_reject}"

            if tiles_to_reject.size > 0
                output, history = Rejection.reject_tiles tiles_to_reject, key, history
            end
            
        end

        history.update(message: "Auto-Rejected #{history.rejected_tiles.count} Tiles, #{history.rejected_footprints.count} Footprints, and #{history.rejected_frame_centers.count} Frame Centers")

        p "done"

    end

end
