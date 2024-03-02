class Doqq < ApplicationRecord
    include Concerns::Archive

    # Associations
    belongs_to :packing_slip, optional: true
    belongs_to :state, optional: true
    belongs_to :county, optional: true
    belongs_to :utm
    belongs_to :vector_metadatum, optional: true
    belongs_to :flown_by, class_name: 'Company', optional: true
    has_one :batch_process_log
    has_one :imagery_path, as: :pathable
    # has_many :rejected_tiles
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs
    has_many :doqq_footprints
    has_many :footprints, -> { distinct }, through: :doqq_footprints
    has_many :rejected_doqqs

    # Scopes
    scope :flown,               -> { where.not(flight_date: nil) }
    scope :not_flown,           -> { where(flight_date: nil) }
    scope :asi_accepted,        -> { where(asi_rejected_date: nil).where.not(flight_date: nil) }
    scope :asi_rejected,        -> { where.not(asi_rejected_date: nil) }
    scope :usda_accepted,       -> { where.not(usda_accepted_date: nil) }
    scope :not_usda_accepted,   -> { where(usda_accepted_date: nil) }
    scope :usda_rejected,       -> { where.not(usda_rejected_date: nil) }
    scope :not_usda_rejected,   -> { where(usda_rejected_date: nil) }
    scope :at_started,          -> { where.not(at_start_date: nil) }
    scope :not_at_started,      -> { where(at_start_date: nil, at_done_date: nil) }
    scope :at_in_process,       -> { where.not(at_start_date: nil).where(at_done_date: nil) }
    scope :at_done,             -> { where.not(at_start_date: nil, at_done_date: nil) }
    scope :dumped,              -> { where.not(dump_date: nil) }
    scope :not_dumped,          -> { where(dump_date: nil) }
    scope :ortho_processing,    -> { where.not(ortho_proc_date: nil) }
    scope :ortho_processed,     -> { where.not(ortho_proc_date: nil) }
    scope :shipped,             -> { where.not(ship_date: nil) }
    scope :not_shipped,         -> { where(ship_date: nil) }
    # scope :has_rejections,      -> {includes(:rejected_tiles).where.not(rejected_tiles: { id: nil })}

    def flown
        # Where reject_date is nil and flight_date is not nil
        asi_rejected_date.nil? && !flight_date.nil? ? true : false
    end

    def not_flown
        # where reject_date and flight_date is nil
        asi_rejected_date.nil? && flight_date.nil? ? true : false
    end

    def at_started
        # where at_start_date is not nil
        !at_start_date.nil? ? true : false
    end

    def not_at_started
        # where at_start_date and at_done_date is nil
        at_start_date.nil? && at_done_date.nil? ? true : false
    end

    def at_in_process
        # where at_stat_date is not nil and at_done_date is nil
        !at_start_date.nil? && at_done_date.nil? ? true : false
    end

    def at_done
        # where at_start_date and at_done_date is not nil
        !at_start_date.nil? && !at_done_date.nil? ? true : false
    end

    def tile_dumped
        !dump_date.nil? ? true : false
    end

    def shipped
        # where ship_date is not nil
        !ship_date.nil? ? true : false
    end

    def not_shipped
        # where ship_date is nil
        !ship_date.nil? ? true : false
    end

    def asi_accepted
        # where ship_date is not nil
        asi_rejected_date.nil? ? true : false
    end

    def asi_rejected
        # where ship_date is not nil
        !asi_rejected_date.nil? ? true : false
    end

    def usda_accepted
        # where ship_date is nil
        !usda_accepted_date.nil? ? true : false
    end

    def usda_rejected
        # where ship_date is nil
        !usda_rejected_date.nil? ? true : false
    end


    def self.remaining_to_fly

        result = []

        State.active_naip.includes(:doqqs).each do |state|

            doqqs = state.doqqs
            total = doqqs.count
            flown = doqqs.flown.count
            not_flown = doqqs.not_flown.count

            percentage_flown = flown.to_f / doqqs.count.to_f * 100
            percentage_remaining = not_flown.to_f / doqqs.count.to_f * 100

            result << {
                id: state.id,
                name: state.name,
                total: total,
                not_flown: not_flown,
                percentage_flown: percentage_flown.round(3),
                percentage_remaining: percentage_remaining.round(3)
            }
        end

        result

    end

    def self.generate_shapefile params
        # Create GeoJSON of doqq still remaining to fly
        # Convert to Shapefile 
        # Zip Shapefiles
        # Download to client

        # set the path variable in case of failure
        path = nil

        begin

            # Get the folder name by converting the current time to seconds
            folder = Time.now.to_i

            path = "#{Rails.root}/assets/doqq_left_to_fly/#{folder}"

            # Create a folder if it doesn't exist
            FileUtils.mkdir_p("#{path}") unless File.directory?(path)
            FileUtils.mkdir_p("#{path}/json")
            FileUtils.mkdir_p("#{path}/shapefile")
            FileUtils.mkdir_p("#{path}/zipped")

            # Set the formated date to a string to be reused
            time_string = Time.now.strftime("%y%m%d")

            shapefiles = []

            factory = RGeo::GeoJSON::EntityFactory.instance

            # Get State
            State.active_naip.where(id: params[:states]).each do |state|

                # Set the file name
                file_name = "#{state.abv}_doqq_left_to_fly_#{time_string}"

                features = Array.new

                # Get all the unflown doqq within the state
                state.doqqs.not_flown.each do |record|
                    features << factory.feature(record.geom, record.id, {
                        QQApfoName: record.qq_apfo_name,
                        acres: record.acres,
                        state_abv: state.abv,
                        state_name: record.state_name,
                        latitude: record.latitude,
                        longitude: record.longitude,
                        min_sun_angle: Rails.application.secrets.min_sun_angle
                    })
                end

                # Creates a text file and saves it to the report directory
                File.open("#{path}/json/#{file_name}.json", "w+") do |f|
                    f.puts(RGeo::GeoJSON.encode(factory.feature_collection(features)).to_json)
                end

                # Convert GeoJSON to Shapefile with ogr2ogr
                `ogr2ogr -f "ESRI Shapefile" #{path}/shapefile/#{file_name}.shp "#{path}/json/#{file_name}.json"`

                shapefiles << file_name

            end

            # Zip the files
            Zip::File.open("#{path}/zipped/doqqs_left_to_fly_#{time_string}.zip", Zip::File::CREATE) do |zipfile|
                shapefiles.each do |shapefile|
                    [".shp", ".shx", ".dbf", ".prj"].each do |ext|
                        zipfile.add("#{shapefile}#{ext}", File.join("#{path}/shapefile/", "#{shapefile}#{ext}"))
                    end
                end
            end

            # Create a new History record
            history = History.new
            history.message = "Generated Shapefile of Doqqs remaining to fly"
            history.action_type = "Generated Shapefile"
            history.url = "#{path}/zipped/doqqs_left_to_fly_#{time_string}.zip"
            history.creator = params[:user]
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

    # create a new Rejected DOQQ
    def reject rejected_date
        self.rejected_doqqs.create(
            rejected_date: rejected_date,
            qq_apfo_name: self.qq_apfo_name,
            flight_date: self.flight_date,
            ortho_proc_date: self.ortho_proc_date,
            dump_date: self.dump_date,
            ship_date: self.ship_date,
            at_start_date: self.at_start_date,
            at_done_date: self.at_done_date,
            usda_accepted_date: self.usda_accepted_date,
            production_upload_date: self.production_upload_date,
            vector_metadatum_id: self.vector_metadatum_id
        )
    end

    # Get the majority of associated flight dates
    # def generate_majority_flight_date

    #     raise Exception, "Cannot generate median Flight Date Time for #{self.id}, No Footprints associated to DOQQ" if self.footprints.count == 0

    #     dates = {}

    #     self.footprints.each do |footprint|

    #         # Testing
    #         # next if footprint.frame_center.nil?

    #         # Format the date to easily associate it
    #         formatted = footprint.flight_date.strftime("%F")

    #         # Create a new empty value if the key doesn't exist
    #         dates[formatted] = 0 if dates[formatted].nil?

    #         # Add 1 to the value
    #         dates[formatted] += 1
    #     end

    #     if !dates.blank?

    #         # Get the majority date
    #         # If multiple then take the first
    #         majority_flight_date = dates.max_by{|k,v| v}[0]

    #         # Save it
    #         self.flight_date = majority_flight_date
    #         self.save

    #     end

    # end

    def generate_median_flight_date_time
       
        raise Exception, "Cannot generate median Flight Date Time for DOQQ #{self.qq_apfo_name}, No Footprints associated to Doqq" if self.footprints.count == 0

        dates = {}

        self.footprints.each do |footprint|

            # Testing
            # next if footprint.frame_center.nil?

            # Format the date to easily associate it
            formatted = footprint.flight_date.strftime("%F")

            # Create a new empty value if the key doesn't exist
            dates[formatted] = 0 if dates[formatted].nil?

            # Add 1 to the value
            dates[formatted] += 1
        end

        if !dates.blank?

            # Get the majority date
            # If multiple then take the first
            majority_flight_date = dates.max_by{|k,v| v}[0]

            hours = {}
            flight_date_time_array = []

            # Now that there is a majority flight date (not time) then I need to get the 
            self.footprints.where(flight_date: majority_flight_date).each do |footprint|

                next if footprint.frame_center.nil?

                # push to 
                flight_date_time_array << footprint.frame_center.flight_date.to_f

            end

            if flight_date_time_array.length > 0

                # Get the median Flight Date Time
                median = flight_date_time_array[flight_date_time_array.length / 2]

                # Average the flight date
                self.median_flight_date_time = Time.at(median).utc
                
                if !self.save
                    raise Exception, "Could not calculat Median Flight Date Time for Tile: #{self.poly_id} | #{self.errors.full_messages.to_sentence}"
                end

            else
                raise Exception, "Could not calculat Median Flight Date Time for Tile: #{self.poly_id}"
            end

        end
    end

    def self.prepare_import params, user

        p "prepare_import"
        p params[:files]
        p "-----"

        response = {
            pass: false,
            message: nil
        }

        path = nil

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Get the folder name by converting the current time to seconds
                folder = Time.now.to_i

                path = "#{Rails.root}/assets/doqq/#{folder}"

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
                        message: "Shapefile has been uploaded to the server and validated. Import process has been added to Job Queue. You will receive a message when it is completed."
                    }
                end

            rescue Exception => exception
                Rails.logger.error "DOQQ Import Prep Error: #{exception.message}"
                response[:pass] = false
                response[:message] = exception.message

                # Delete the files
                FileUtils.rm_rf("#{path}/") if path

                raise ActiveRecord::Rollback
            end
        end

        if response[:pass]
            Doqq.delay.import params, path, user
        end

        response

    end

    # Update the filenames
    def self.update_filename
        # find the tiles that have been flown
        Doqq.flown.each do |doqq|
            doqq.update(
                filename: doqq.build_filename
            )
        end
    end

    def build_filename
        # Example: "m_3509320_ne_15_060_20200721"
        # "<n>_<lat><lon><quad>_<loc>_<UTM>_30_#{flight_date.strftime("%Y%m%d")}"
        "m_#{apfo_name}_#{quadrant}_#{utm_zone}_060_#{median_flight_date_time.strftime("%Y%m%d")}"
    end

    # Imports the shapefile
    def self.import params, path, user

        # create an Error array to hold any messages
        # output = {
        #     pass: false,
        #     errors: [],
        #     count: 0
        # }
        count = 0

        job = Job.create(
            started_at: Time.now,
            message: "Processing Request...",
            active: true,
            process_type: "DOQQ Import",
            creator: user
        )

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Create upload instance to track the doqq created
                upload = Upload.create(
                    folder_path: "#{path}",
                    upload_type: "DOQQ",
                    uploader: user
                )

                # Find the shapefile in the folder to reproject
                shp = Dir.glob("#{path}/original/*.shp")

                if shp.empty?
                    # output[:errors] << "Could not find shapefile to upload"
                    # FileUtils.rm_rf(path)
                    # upload.destroy
                    # raise ActiveRecord::Rollback
                    raise Exception, "Could not find shapefile to upload"
                end

                # Call ogr2ogr to reproject the shapefile to 4326
                `ogr2ogr -f "ESRI Shapefile" -t_srs EPSG:4326 #{path}/projected/doqq.shp #{shp.first} -dim 2`

                RGeo::Shapefile::Reader.open("#{path}/projected/doqq.shp") do |file|
                    # puts "File contains #{file.num_records} records."
                    p file
                    p "--------------------"
                    file.each do |record|
                        puts "Record number #{record.attributes}:"

                        # county = County.select(:id, :name, :state_id).find_by(full_fips: record.attributes["FIPS"])

                        # if county.nil?
                        #     raise Exception, "Could not match County with FIPS: #{record.attributes["FIPS"]}"
                        # end

                        # Hard code this for Naip 2022
                        # state = State.select(:id, :name).find_by(abv: record.attributes["ST"])
                        # state = State.select(:id, :name).find_by(abv: record.attributes["ST"])
                        # state = 

                        # raise Exception, "Could not match State with abbreviation: #{record.attributes["ST"]}" if state.nil?

                        # Find the UTM zone
                        utm = Utm.select(:id, :zone).find_by(zone: record.attributes["ZONE"])

                        if utm.nil?
                            raise Exception, "Could not find UTM: #{record.attributes["ZONE"]}"
                        end

                        # # Get the UTM zone
                        # sql = "select id, zone from utms u where st_intersects(ST_GeomFromText('#{record.geometry.to_s}'), u.geom) 
                        #     and (st_area(st_intersection(ST_GeomFromText('#{record.geometry.to_s}'), u.geom))/st_area(ST_GeomFromText('#{record.geometry.to_s}'))) > .5"
                        # result = ActiveRecord::Base.connection.execute(sql)

                        # p "+++++++"
                        # p result[0]
                        # p "+++++++"

                        state_split = record.attributes["QUADST"].split(" ")

                        county_ids = []

                        state_split.each do |state|

                            # Get the state
                            state_id = State.exclude_geom.find_by(abv: state).id

                            sql = "select id from counties u where st_intersects(ST_GeomFromText('#{record.geometry.to_s}'), u.geom) AND state_id = #{state_id}"
                            result = ActiveRecord::Base.connection.execute(sql)

                            next if result.count == 0

                            arr = result.map {|r| r["id"]}

                            county_ids << arr.flatten

                        end

                        state = State.find(params[:state_id])

                        # Import here
                        doqq = Doqq.new(
                            project_state_name: state.name,
                            project_no: "",
                            q_key: record.attributes["QKEY"], 
                            apfo_name: record.attributes["APFONAME"],
                            qq_apfo_name: record.attributes["QQAPFONAME"],
                            acres: record.attributes["AREA_SQ_MI"].to_d * 640, 
                            sq_miles: record.attributes["AREA_SQ_MI"], 
                            quadrant: record.attributes["QUADRANT"], 
                            qq_name: record.attributes["QQNAME"], 
                            latitude: record.attributes["YCOORD"], 
                            longitude: record.attributes["XCOORD"], 
                            quad_state_abvs: record.attributes["QUADST"], 
                            geom: record.geometry,
                            # county_id: county.id,
                            # county_name: county.name,
                            state_id: state.id,
                            state_name: state.name,
                            state_abv: state.abv,
                            project_state_id: state.id,
                            utm_id: utm.id,
                            utm_zone: utm.zone,
                            counties: county_ids.uniq.join(" ")
                        )

                        # pp doqq

                        if !doqq.save
                            raise Exception, doqq.errors.full_messages.to_sentence
                        end

                        upload.doqqs << doqq

                        count += 1
                    end
                end

                # Add the number of files uploaded
                upload.number_uploaded = count
                upload.save
                
                if count > 0

                    Doqq.associate_counties

                    # Create a new History record
                    history = History.new
                    history.message = "Uploaded #{count} DOQQ!"
                    history.action_type = "Upload DOQQ"
                    history.creator = user
                    history.save

                    # add records to polymorphic association
                    history.uploads << upload
                    history.doqqs = upload.doqqs

                    job.update(
                        finished_at: Time.now,
                        active: false,
                        success: true,
                        upload: upload,
                        message: "Uploaded #{count} DOQQ!"
                    )

                    # Log and send email
                    Mailbox.ship({
                        users: [user],
                        subject: "DOQQ Import Success",
                        message: "DOQQ Import finished successfully, #{upload.doqqs.count} DOQQ were imported to the system."
                    })

                    # PostmasterMailer.notify(user, "DOQQ Import finished successfully, #{upload.doqqs.count} DOQQ were imported to the system.", "USDA #{Rails.application.secrets.project_year}: DOQQ Import Success - #{Time.now.strftime("%m/%d/%Y")}").deliver

                elsif count == 0
                    raise Exception, "No Easement Features were uploaded, please check the shapefile for a valid projection and try again."
                else
                    raise Exception, "Something went wrong"
                end


            rescue Exception => exception
                p exception.message
                Rails.logger.error "DOQQ Import Error: #{exception.message}"

                # Delete the Upload and History
                upload.destroy if upload
                history.destroy if history

                # Delete the files
                FileUtils.rm_rf("#{path}/") if path

                # Log and send email
                Mailbox.ship({
                    users: [user],
                    subject: "DOQQ Import Failed",
                    message: "DOQQ Import Failed, please check the shapefile for a valid projection and try again."
                })

                # # Send email to notified it failed
                # PostmasterMailer.notify(user, "DOQQ Import Failed, please check the shapefile for a valid projection and try again.", "USDA #{Rails.application.secrets.project_year}: DOQQ Import Failed - #{Time.now.strftime("%m/%d/%Y")}").deliver

                # Rollback the database
                ActiveRecord::Rollback

                # Update the job
                job.update(
                    finished_at: Time.now,
                    active: false,
                    success: false,
                    message: "Import Failed",
                    error_message: exception.message
                )
            end
        end
    end

    def self.flight_crew_report companies, states, date_flown_from, date_flown_end

        obj = {}
        ids = []

        footprint_ids = Footprint.naip.where(state_id: states.pluck(:id), flown_by_id: companies.pluck(:id), flight_date: date_flown_from..date_flown_end).pluck(:id)

        DoqqFootprint.includes(:footprint, doqq: [:rejected_doqqs]).where(footprint_id: footprint_ids).order("footprints.flown_by_name DESC, doqqs.state_name DESC, footprints.pilot_name DESC, Footprints.camera_operator_name DESC").each do |df|

            next if ids.include? df.doqq.id

            key = "#{df.footprint.flown_by_id}_#{df.doqq.state_id}_#{df.footprint.pilot_name}_#{df.footprint.camera_operator_name}"

            obj[key] = {} if obj[key].nil?

            if obj[key].empty?
                obj[key] = {
                    flown_by: df.footprint.flown_by_name,
                    state_name: df.footprint.camera_name,
                    pilot: df.footprint.pilot_name,
                    sensor_operator: df.footprint.camera_operator_name,
                    flown: 1,
                    asi_accepted: 1,
                    asi_rejected: df.doqq.rejected_doqqs.count,
                    usda_accepted: df.doqq.usda_accepted ? 1 : 0,
                    usda_rejected: 0,
                }
            else
                obj[key][:flown] += 1
                obj[key][:asi_accepted] += 1
                obj[key][:asi_rejected] += df.doqq.rejected_doqqs.count
                obj[key][:usda_accepted] += df.doqq.usda_accepted ? 1 : 0
                obj[key][:usda_rejected] += 0
            end

            ids << df.doqq.id

        end

        obj.flatten.select { |record| record.class == Hash && !record.empty? }

    end

    def self.associate_counties

        Doqq.all.update(counties: nil)

        Doqq.all.each do |doqq|

            state_split = doqq.quad_state_abvs.split(" ")

            county_ids = []

            state_split.each do |state|

                state_id = State.exclude_geom.find_by(abv: state).id

                sql = "select id from counties u where st_intersects(ST_GeomFromText('#{doqq.geom.to_s}'), u.geom) AND state_id = #{state_id}"
                result = ActiveRecord::Base.connection.execute(sql)

                if result.count == 0
                    next
                end

                arr = result.map {|r| r["id"]}

                county_ids << arr.flatten

            end

            # p "-------------"
            # p county_ids
            # p "-------------"

            doqq.update(counties: county_ids.uniq.join(" "))
        end
    end

    def self.return_biggest_counties_size

        biggest = 0

        Doqq.all.each do |doqq|

            size = doqq.counties.split(" ").size

            biggest = size if size > biggest

        end

        biggest

    end

end
