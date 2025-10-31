class Easement < ApplicationRecord
    include Concerns::Archive
    require 'zip'
    require 'rgeo/shapefile'

    # Associations
    belongs_to :county
    belongs_to :state
    belongs_to :project_state, class_name: 'State'
    belongs_to :utm
    belongs_to :time_zone
    belongs_to :upload
    belongs_to :plane, optional: true
    belongs_to :camera, optional: true
    belongs_to :flown_by, class_name: 'Company', optional: true
    belongs_to :contract_award
    has_many :tiles, dependent: :destroy
    has_many :rejected_tiles, dependent: :destroy
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs
    accepts_nested_attributes_for :tiles

    # => Status based Scopes
    scope :sl,                  -> { where(project: "SL") }
    scope :nri,                 -> { where(project: "NRI") }
    scope :nri_sl,              -> { where(project: ["NRI", "SL"]) }
    scope :flown,               -> { where.not(flight_date: nil) }
    scope :not_flown,           -> { where(flight_date: nil) }
    scope :ortho_processed,     -> { includes(:tiles).where.not(tiles: {ortho_proc_date: nil}) }
    scope :not_ortho_processed, -> { includes(:tiles).where(tiles: {ortho_proc_date: nil}) }
    scope :shipped,             -> { includes(:tiles).where.not(tiles: {ship_date: nil}) }
    scope :not_shipped,         -> { includes(:tiles).where(tiles: {ship_date: nil}) }
    scope :exclude_geom,        -> { select( Easement.attribute_names - ['geom'] ) }
    scope :has_multiple_geom,   -> { where(multiple_geom: true) }

    # Validations
    validates :poly_id, uniqueness: true

    def flown?
        self.flight_date ? true : false
    end

    def self.remaining_to_fly project

        result = []

        if project == "SL"
            states = State.active_sl.includes(:easements)
        elsif project == "NRI"
            states = State.active_nri.includes(:easements)
        end

        states.each do |state|

            if project == "SL"
                easements = state.easements.sl
            elsif project == "NRI"
                easements = state.easements.nri
            end
    
            total = easements.count
            flown = easements.flown.count
            not_flown = easements.not_flown.count

            percentage_flown = flown.to_f / easements.count.to_f * 100
            percentage_remaining = not_flown.to_f / easements.count.to_f * 100

            remaining_acres = easements.not_flown.sum(&:acres).to_f

            result << {
                id: state.id,
                name: state.name,
                total: total,
                not_flown: not_flown,
                remaining_acres: remaining_acres.round(2),
                percentage_flown: percentage_flown.round(3),
                percentage_remaining: percentage_remaining.round(3)
            }
        end

        result

    end

    # def self.generate_daily_progress_report flight_date, rejected_date_from, rejected_date_to

    #     obj = {}

    #     # # Get all Easments flown on the selected date and pluck the poly_id
    #     # obj[:nri_accepted] = Tile.flown.asi_accepted.not_usda_rejected.where(flight_date: flight_date, project: "NRI").order(:poly_id).pluck(:poly_id)
    #     # obj[:nri_rejected] = []
    #     # obj[:nri_rejected_and_reported] = []

    #     # if rejected_date_from

    #     #     args = { project: "NRI" }

    #     #     if rejected_date_to
    #     #         args[:rejected_date] = rejected_date_from..rejected_date_to
    #     #     else
    #     #         args[:rejected_date] = rejected_date_from..Time.now
    #     #     end

    #     #     RejectedTile.where(args).order(:poly_id).each do |tile|
    #     #         if tile.reported_date
    #     #             obj[:nri_rejected_and_reported] << {flight_date: tile.flight_date, poly_id: tile.poly_id, reported_date: tile.reported_date}
    #     #         else
    #     #             obj[:nri_rejected] << {flight_date: tile.flight_date.strftime("%d-%^b-%g"), poly_id: tile.poly_id}
    #     #             tile.update(reported_date: Time.now)
    #     #         end
    #     #     end
    #     # end

    #     obj[:sl_accepted] = Tile.flown.where(flight_date: flight_date, project: "SL").order(:poly_id).pluck(:poly_id)
    #     obj[:sl_rejected] = []
    #     obj[:sl_rejected_and_reported] = []
    #     obj[:pass] = false

    #     if rejected_date_from

    #         args = { project: "SL" }

    #         if rejected_date_to
    #             args[:rejected_date] = rejected_date_from..rejected_date_to
    #         else
    #             args[:rejected_date] = rejected_date_from..Time.now
    #         end

    #         RejectedTile.where(args).order(:poly_id).each do |tile|
    #             if tile.reported_date
    #                 obj[:sl_rejected_and_reported] << {flight_date: tile.flight_date, poly_id: tile.poly_id, reported_date: tile.reported_date}
    #             else
    #                 obj[:sl_rejected] << {flight_date: tile.flight_date.strftime("%d-%^b-%g"), poly_id: tile.poly_id}
    #                 tile.update(reported_date: Time.now)
    #             end
    #         end
    #     end

    #     # Build the file name by recursively checking if the file exists
    #     file_name = Easement.get_report_version flight_date, nil

    #     # Creates a text file and saves it to the report directory
    #     File.open("#{Rails.application.secrets.report_folder}#{file_name}", "w+") do |f|

    #         # if obj[:nri_accepted].count > 0 || obj[:nri_rejected].count > 0
    #         #     f.puts("----- NRI Daily Progress Report -----")

    #         #     if obj[:nri_rejected_and_reported].count > 0
    #         #         f.puts("")
    #         #         f.puts(" * DO NOT INCLUDE LINES BELOW IN REPORT *")
    #         #         f.puts("Rejected NRI Tiles that were not included but within date range:")
    #         #         obj[:nri_rejected_and_reported].each do |tile|
    #         #             f.puts(" - #{tile[:poly_id]} with Flight Date of #{tile[:flight_date].strftime("%m/%d/%Y")} reported on #{tile[:reported_date].strftime("%m/%d/%Y")}")
    #         #         end
    #         #         f.puts(" * DO NOT INCLUDE LINES ABOVE IN REPORT *")
    #         #         f.puts("")
    #         #     end

    #         #     f.puts("Subject Line:")
    #         #     f.puts("NRI #{flight_date.strftime("%d-%^b-%g")}")
    #         #     f.puts("")
    #         #     f.puts("Body:")

    #         #     if obj[:nri_accepted].count > 0
    #         #         obj[:nri_accepted].each do |poly_id|
    #         #             f.puts("#{flight_date.strftime("%d-%^b-%g")}   #{poly_id}   A")
    #         #         end
    #         #     end

    #         #     if obj[:nri_rejected].count > 0
    #         #         obj[:nri_rejected].each do |tile|
    #         #             f.puts("#{tile[:flight_date]}   #{tile[:poly_id]}   R")
    #         #         end
    #         #     end

    #         #     f.puts("")
    #         #     f.puts("")
    #         # end

    #         if obj[:sl_accepted].count > 0 || obj[:sl_rejected].count > 0
    #             f.puts("----- SL Daily Progress Report -----")

    #             if obj[:sl_rejected_and_reported].count > 0
    #                 f.puts("")
    #                 f.puts(" * DO NOT INCLUDE LINES BELOW IN REPORT * ")
    #                 f.puts("Rejected NRI Tiles that were not included but within date range:")
    #                 obj[:sl_rejected_and_reported].each do |tile|
    #                     f.puts(" - #{tile[:poly_id]} with Flight Date of #{tile[:flight_date].strftime("%m/%d/%Y")} reported on #{tile[:reported_date].strftime("%m/%d/%Y")}")
    #                 end
    #                 f.puts(" * DO NOT INCLUDE LINES ABOVE IN REPORT *")
    #                 f.puts("")
    #             end

    #             f.puts("Subject Line:")
    #             f.puts("SL #{flight_date.strftime("%d-%^b-%g")}")
    #             f.puts("")
    #             f.puts("Body:")

    #             if obj[:sl_accepted].count > 0
    #                 obj[:sl_accepted].each do |poly_id|
    #                     f.puts("#{flight_date.strftime("%d-%^b-%g")}   #{poly_id}   A")
    #                 end
    #             end

    #             if obj[:sl_rejected].count > 0
    #                 obj[:sl_rejected].each do |tile|
    #                     f.puts("#{tile[:flight_date]}   #{tile[:poly_id]}   R")
    #                 end
    #             end
    #         end

    #     end

    #     if obj[:sl_accepted].count > 0 || obj[:sl_rejected].count > 0 || obj[:sl_rejected_and_reported].count > 0
    #         obj[:pass] = true
    #     end

    #     # Return the results to render on the page
    #     obj

    # end

    def self.sites_yet_to_be_acquired_export
        # Iterate the PreFlightRecords that do not have any PostFlightRecords
        # Add to CSV
        # Write to location

        fields = ["poly_id"]

        CSV.open("/media/sf_shared/temp/sli/easements_yet_to_be_acquired.csv", "wb") do |csv|
            csv << ["county", "state", "fips"] + fields

            Easement.where(flight_date: nil).each do |record|
                result = []
    
                fields.each do |field|
                    result << "#{record[field]}"
                end
                
                csv << [record.county.name, record.county.state.name, record.county.full_fips] + result
            end
        end

    end

    def self.prepare_import params, user

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

                path = "#{Rails.root}/assets/easements/#{folder}"

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
                Rails.logger.error "Easement Import Prep Error: #{exception.message}"
                response[:pass] = false
                response[:message] = exception.message

                # Delete the files
                FileUtils.rm_rf("#{path}/") if path

                raise ActiveRecord::Rollback
            end
        end

        if response[:pass]
            Easement.delay.import params, path, user
        end

        response

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

        # Create the job outside the transaction block so it does not get rolled back in an error
        job = Job.create(
            started_at: Time.now,
            message: "Processing Request...",
            active: true,
            process_type: "Buffered Easement Import",
            creator: user
        )

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Create upload instance to track the easements created
                upload = Upload.create(
                    folder_path: "#{path}",
                    upload_type: "Easement",
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
                `ogr2ogr -f "ESRI Shapefile" -t_srs EPSG:4326 #{path}/projected/easements.shp #{shp.first} -dim 2`

                RGeo::Shapefile::Reader.open("#{path}/projected/easements.shp") do |file|
                    # puts "File contains #{file.num_records} records."
                    p file
                    p "--------------------"
                    file.each do |record|

                        if params[:project] == "SL"

                            puts "Easement Number: #{record.attributes["NESTID"]}"
                            # pp record.attributes

                            # Find the State 
                            state = State.find_by(abv: record.attributes["STATE_ABBR"])

                            # p "=-=-=-=-=-=-=-="
                            # p state.name
                            # p record.attributes["STATE_ABBR"]
                            # p "=-=-=-=-=-=-=-="

                            if state.nil?
                                raise Exception, "Could not match State with FIPS: #{record.attributes["STATE_ABBR"]}"
                            end

                            # Find the county based on the selected state
                            county = state.counties.find_by(full_fips: "#{record.attributes["FIPS"]}")

                            p "---------"
                            p "SHP County: #{record.attributes["NAME"]}"
                            p "SHP FIPS: #{record.attributes["FIPS"]}"
                            p "County: #{county.name}"
                            p "County FIPS: #{county.full_fips}"
                            p "---------"

                            if county.nil?
                                raise Exception, "Could not match County with FIPS: #{record.attributes["FIPS"]} in State: #{record.attributes["STATE_ABBR"]}"
                            end

                            p state.name

                            # Find the contract award
                            contract_award = ContractAward.find_by(state: state, project: params[:project])

                            # create the easement
                            easement = Easement.new(
                                # scale: record.attributes["Scale"],
                                acres: record.attributes["CalcAcres_"],
                                # buffer_acres: record.attributes["BufferAcre"],
                                latitude: record.attributes["Latitude"],
                                longitude: record.attributes["Longitude"],
                                original_poly_id: record.attributes["NESTID"],
                                poly_id: record.attributes["NESTID"],
                                project: params[:project],
                                project_no: contract_award.project_no,
                                project_state_name: state.name,
                                # phase: record.attributes["phase"],
                                # status: record.attributes["Status"],
                                # usda_region: record.attributes["USDARegion"],
                                # asi_block: record.attributes["ASI_Block"],
                                original_fid: record.attributes["OBJECTID"],
                                county_name: county.name,
                                state_name: state.name,
                                state_abv: state.abv,
                                geom: record.geometry,
                                contract_award: contract_award,
                                county: county,
                                state: state,
                                project_state: state,
                                upload: upload
                            )

                        else

                            puts "Poly ID: #{record.attributes["POLY_ID"]}"
                            pp record.attributes

                            p record.attributes["FIPS"]

                            # Find the county based on the selected state
                            county = County.find_by(full_fips: "#{record.attributes["FIPS"]}")

                            if county.nil?
                                raise Exception, "Could not match County with FIPS: #{record.attributes["FIPS"]}"
                            end

                            state = county.state

                            if state.nil?
                                raise Exception, "Could not match State with FIPS: #{record.attributes["STATE_ABBR"]}"
                            end

                            # Find the contract award
                            contract_award = ContractAward.find_by(state: state, project: params[:project])

                            # create the easement
                            easement = Easement.new(
                                # scale: record.attributes["Scale"],
                                acres: record.attributes["CalcAcres_"],
                                # buffer_acres: record.attributes["BufferAcre"],
                                latitude: record.geometry.centroid.y,
                                longitude: record.geometry.centroid.x,
                                original_poly_id: record.attributes["NESTID"],
                                poly_id: record.attributes["NESTID"],
                                project: params[:project],
                                project_no: contract_award.project_no,
                                project_state_name: state.name,
                                # phase: record.attributes["phase"],
                                # status: record.attributes["Status"],
                                # usda_region: record.attributes["USDARegion"],
                                # asi_block: record.attributes["ASI_Block"],
                                original_fid: record.attributes["FID"],
                                county_name: county.name,
                                state_name: state.name,
                                state_abv: state.abv,
                                geom: record.geometry,
                                contract_award: contract_award,
                                county: county,
                                state: state,
                                project_state: state,
                                upload: upload
                            )

                        end

                        # check that the easement is within the associated county
                        # matched_county = County.find_by("counties.full_fips = '#{record.attributes["FIPS"]}' AND st_intersects(counties.geom::geometry, ST_SetSRID(ST_GeomFromText('#{easement.geom.to_s}'),4326))")

                        # # pp matched_county

                        # if (!matched_county || matched_county.id != county.id) && !["15009_030401R", "72115_030302R"].include?(easement.poly_id)
                        #     pp easement
                        #     raise Exception, "Easement #{easement.poly_id} lat/long does not exist within specified county (fips match: #{county.full_fips} | loc match: #{matched_county.nil? ? "NA" : matched_county.full_fips})"
                        # end

                        # Get the footprint UTM zone
                        sql = "select id, zone, (st_area(st_intersection(ST_GeomFromText('#{easement.geom.to_s}'), u.geom))/st_area(ST_GeomFromText('#{easement.geom.to_s}'))) as area
                        from utms u where st_intersects(ST_GeomFromText('#{easement.geom.to_s}'), u.geom)
                        order by (st_area(st_intersection(ST_GeomFromText('#{easement.geom.to_s}'), u.geom))/st_area(ST_GeomFromText('#{easement.geom.to_s}'))) DESC"

                        result = ActiveRecord::Base.connection.execute(sql)
                        easement.utm_id = result[0]["id"]
                        easement.utm_zone = "#{result[0]["zone"]}N"

                        # Get the timezone
                        sql = "select id
                        from time_zones tz where st_intersects(ST_GeomFromText('#{easement.geom.to_s}'), tz.geom)
                        order by (st_area(st_intersection(ST_GeomFromText('#{easement.geom.to_s}'), tz.geom))/st_area(ST_GeomFromText('#{easement.geom.to_s}'))) DESC"

                        result = ActiveRecord::Base.connection.execute(sql)
                        easement.time_zone_id = result[0]["id"]

                        # Check the number of geometries
                        sql = "SELECT ST_NumGeometries(ST_GeomFromText('#{easement.geom.to_s}')) as num_geom"
                        result = ActiveRecord::Base.connection.execute(sql)

                        easement.multiple_geom = result[0]["num_geom"] > 1

                        if !easement.save
                            p easement.errors.full_messages.to_sentence
                            raise Exception, easement.errors.full_messages.to_sentence
                        end

                        count += 1
                    end
                end

                # Add the number of files uploaded
                upload.number_uploaded = count
                upload.save

                if count > 0

                    # Create a new History record
                    history = History.new
                    history.message = "Uploaded #{count} Buffered Easements and generated their associated Tiles"
                    history.action_type = "Upload Buffered Easements"
                    history.creator = user
                    history.save

                    # add records to polymorphic association
                    history.uploads << upload
                    history.easements = upload.easements

                    # Build the Tiles
                    Tile.generate user, params[:project]

                    job.update(
                        finished_at: Time.now,
                        active: false,
                        success: true,
                        upload: upload,
                        message: "Uploaded #{count} Buffered Easements and generated their associated Tiles"
                    )

                    # Log and send email
                    Mailbox.ship({
                        users: [user],
                        subject: "Easement Import Succeeded",
                        message: "Easement Import finished successfully, #{upload.easements.count} Easments were imported to the system."
                    })

                    # PostmasterMailer.notify(user, "Easement Import finished successfully, #{upload.easements.count} Easments were imported to the system.", "USDA #{Rails.application.secrets.project_year}: Easement Import Success - #{Time.now.strftime("%m/%d/%Y")}").deliver

                elsif count == 0
                    raise Exception, "No Easement Features were uploaded, please check the shapefile for a valid projection and try again."
                else
                    raise Exception, "Something went wrong"
                end

            rescue Exception => exception
                p exception.message
                Rails.logger.error "Easement Import Error: #{exception.message}"
                # output[:pass] = false
                # output[:errors] = exception.message

                p "-----------"
                p exception.backtrace.count
                exception.backtrace.each do |x|
                    next if !x.include? "easement.rb"
                    x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
                   p [$1,$2,$4]
                end
                p "-----------"

                # Delete the Upload and History
                # upload.destroy if upload
                # history.destroy if history

                # Delete the files
                # FileUtils.rm_rf("#{path}/") if path

                # Log and send email
                Mailbox.ship({
                    users: [user],
                    subject: "Easement Import Failed",
                    message: "Easement Import Failed, please check the shapefile for a valid projection and try again."
                })

                # Send email to notified it failed
                # PostmasterMailer.notify(user, "Easement Import Failed, please check the shapefile for a valid projection and try again.", "USDA #{Rails.application.secrets.project_year}: Easement Import Failed - #{Time.now.strftime("%m/%d/%Y")}").deliver

                ActiveRecord::Rollback

                job.update(
                    finished_at: Time.now,
                    active: false,
                    success: false,
                    message: "Import Failed",
                    error_message: exception.message
                )
            end
        end

        p "done"

        # Return output to controller
        # output

    end

    def self.generate_shapefile_and_rejected_ready_to_fly params
        rejected = self.generate_rejected_ready_to_fly params
        shp = self.generate_shapefile params

        p "DONE"
        p "---------"
        p rejected
        p shp
        p "---------"

        # Extract the history ids and zip the files into the shp history
        rejected_history = History.find(rejected[:history_id])
        rejected_path = File.dirname(File.dirname(rejected_history.url))

        shp_history = History.find(shp[:history_id])
        shp_path = File.dirname(File.dirname(shp_history.url))
        shp_filename = File.basename(shp_history.url)

        # p "#{rejected_path}/shapefile/."
        # p "#{shp_path}/shapfile"
        # p shp_filename

        FileUtils.cp_r("#{rejected_path}/shapefile/.", "#{shp_path}/shapefile")

        File.delete(shp_history.url)

        # Get all entries in the folder
        filenames = Dir.entries("#{shp_path}/shapefile").select do |entry|
            File.file?(File.join("#{shp_path}/shapefile", entry))
        end
        
        # Remove extensions and get unique names
        shapefiles = filenames.map do |name|
            File.basename(name, File.extname(name))
        end.uniq

        # Zip the files
        Zip::File.open(shp_history.url, Zip::File::CREATE) do |zipfile|
            shapefiles.each do |shapefile|
                [".shp", ".shx", ".dbf", ".prj"].each do |ext|
                    zipfile.add("#{shapefile}#{ext}", File.join("#{shp_path}/shapefile/", "#{shapefile}#{ext}"))
                end
            end
        end

        return {
            state: true,
            history_id: shp_history.id
        }

    end

    def self.generate_rejected_ready_to_fly params
        # Create GeoJSON of easements still remaining to fly
        # Convert to Shapefile 
        # Zip Shapefiles
        # Download to client

        # set the path variable in case of failure
        path = nil

        project = params[:project]

        begin

            # Get the folder name by converting the current time to seconds
            folder = Time.now.to_i

            path = "#{Rails.root}/assets/rejected_easements_left_to_fly/#{folder}"

            # Create a folder if it doesn't exist
            FileUtils.mkdir_p("#{path}") unless File.directory?(path)
            FileUtils.mkdir_p("#{path}/json")
            FileUtils.mkdir_p("#{path}/shapefile")
            FileUtils.mkdir_p("#{path}/zipped")

            # Set the formated date to a string to be reused
            time_string = Time.now.strftime("%y%m%d")

            shapefiles = []

            factory = RGeo::GeoJSON::EntityFactory.instance

            # Set the file name
            file_name = "rejected_easements_left_to_fly_#{project}_#{time_string}"

            features = Array.new

            # Get State
            State.where(id: params[:states]).each do |state|

                if project == "SL"
                    easements = state.easements.sl.not_flown.includes(:tiles, :time_zone)
                elsif project == "NRI"
                    easements = state.easements.nri.not_flown.includes(:tiles, :time_zone)
                end

                # Get all the unflown easements within the state
                easements.each do |record|

                    rejected_tiles = record.rejected_tiles.order(:rejected_date)

                    p "------"
                    p record.poly_id
                    p rejected_tiles.count

                    next if rejected_tiles.count === 0

                    rej_msg = nil
                    last_flight = nil
                    last_rej = nil
                    num_rej = rejected_tiles.count

                    # check for rejections
                    if rejected_tiles.count > 0
                        rej_msg = rejected_tiles.last.rejection_type
                        last_flight = rejected_tiles.last.flight_date
                        last_rej = rejected_tiles.last.rejected_date
                    end

                    p rej_msg

                    obj = {
                        EasementNo: record.poly_id,
                        acres: record.acres,
                        block: record.asi_block,
                        county_name: record.county_name,
                        state_abv: state.abv,
                        state_name: record.state_name,
                        latitude: record.latitude,
                        longitude: record.longitude,
                        multi_geom: record.multiple_geom ? "True" : "False",
                        priority: record.priority,
                        # min_sun_angle: Rails.application.secrets.min_sun_angle,
                        rej_msg: rej_msg,
                        last_flight: last_flight,
                        last_rej: last_rej,
                        num_rej: num_rej,
                    }

                    pp obj

                    FlightTime.where(tile_id: record.tiles.pluck(:id)).order(:flight_date).each do |ft|
                        # obj[ft.start_date.strftime("%m_%d_start").to_sym] = ft.start_date.in_time_zone(record.time_zone.name).strftime("%H:%M").to_s
                        # obj[ft.end_date.strftime("%m_%d_end").to_sym] = ft.end_date.in_time_zone(record.time_zone.name).strftime("%H:%M").to_s

                        obj[ft.flight_date.strftime("%A").to_sym] = "#{ft.flight_date.strftime("%m/%d")} #{ft.start_date.strftime('%H:%M')} - #{ft.end_date.strftime('%H:%M')}"
                    end

                    features << factory.feature(record.geom, record.id, obj)
                end

            end

            # Creates a text file and saves it to the report directory
            File.open("#{path}/json/#{file_name}.json", "w+") do |f|
                f.puts(RGeo::GeoJSON.encode(factory.feature_collection(features)).to_json)
            end

            # Convert GeoJSON to Shapefile with ogr2ogr
            `ogr2ogr -f "ESRI Shapefile" -fieldTypeToString Date,Time #{path}/shapefile/#{file_name}.shp "#{path}/json/#{file_name}.json"`

            shapefiles << file_name

            # Zip the files
            Zip::File.open("#{path}/zipped/#{project}_rejected_easements_to_fly_#{time_string}.zip", Zip::File::CREATE) do |zipfile|
                shapefiles.each do |shapefile|
                    [".shp", ".shx", ".dbf", ".prj"].each do |ext|
                        zipfile.add("#{shapefile}#{ext}", File.join("#{path}/shapefile/", "#{shapefile}#{ext}"))
                    end
                end
            end

            # output[:file] = "#{path}/zipped/easements_left_to_fly_#{time_string}.zip"
            # output[:file_name] = "easements_left_to_fly_#{time_string}.zip"

            # Create a new History record
            history = History.new
            history.message = "Generated Shapefile of #{project} Easements to Fly"
            history.action_type = "Exported Easements to Fly Shapefile"
            history.url = "#{path}/zipped/#{project}_rejected_easements_to_fly_#{time_string}.zip"
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

    def self.generate_shapefile params
        # Create GeoJSON of easements still remaining to fly
        # Convert to Shapefile 
        # Zip Shapefiles
        # Download to client

        # set the path variable in case of failure
        path = nil

        project = params[:project]

        begin

            # Get the folder name by converting the current time to seconds
            folder = Time.now.to_i

            path = "#{Rails.root}/assets/easements_left_to_fly/#{folder}"

            # Create a folder if it doesn't exist
            FileUtils.mkdir_p("#{path}") unless File.directory?(path)
            FileUtils.mkdir_p("#{path}/json")
            FileUtils.mkdir_p("#{path}/shapefile")
            FileUtils.mkdir_p("#{path}/zipped")

            # Set the formated date to a string to be reused
            time_string = Time.now.strftime("%y%m%d")

            shapefiles = []

            factory = RGeo::GeoJSON::EntityFactory.instance

            # Set the file name
            file_name = "easements_left_to_fly_#{project}_#{time_string}"

            features = Array.new

            # Get State
            State.where(id: params[:states]).each do |state|

                if project == "SL"
                    easements = state.easements.sl.not_flown.includes(:tiles, :time_zone)
                elsif project == "NRI"
                    easements = state.easements.nri.not_flown.includes(:tiles, :time_zone)
                end

                # Get all the unflown easements within the state
                easements.each do |record|

                    rejected_tiles = record.rejected_tiles.order(:rejected_date)

                    p "------"
                    p record.poly_id
                    p rejected_tiles.count

                    rej_msg = nil
                    last_flight = nil
                    last_rej = nil
                    num_rej = rejected_tiles.count

                    # check for rejections
                    if rejected_tiles.count > 0
                        rej_msg = rejected_tiles.last.rejection_type
                        last_flight = rejected_tiles.last.flight_date
                        last_rej = rejected_tiles.last.rejected_date
                    end

                    obj = {
                        EasementNo: record.poly_id,
                        acres: record.acres,
                        block: record.asi_block,
                        county_name: record.county_name,
                        state_abv: state.abv,
                        state_name: record.state_name,
                        latitude: record.latitude,
                        longitude: record.longitude,
                        multi_geom: record.multiple_geom ? "True" : "False",
                        priority: record.priority,
                        min_sun_angle: Rails.application.secrets.min_sun_angle,
                        rej_msg: rej_msg,
                        last_flight: last_flight,
                        last_rej: last_rej,
                        num_rej: num_rej,
                    }

                    FlightTime.where(tile_id: record.tiles.pluck(:id)).order(:flight_date).each do |ft|
                        # obj[ft.start_date.strftime("%m_%d_start").to_sym] = ft.start_date.in_time_zone(record.time_zone.name).strftime("%H:%M").to_s
                        # obj[ft.end_date.strftime("%m_%d_end").to_sym] = ft.end_date.in_time_zone(record.time_zone.name).strftime("%H:%M").to_s

                        obj[ft.flight_date.strftime("%A").to_sym] = "#{ft.flight_date.strftime("%m/%d")} #{ft.start_date.strftime('%H:%M')} - #{ft.end_date.strftime('%H:%M')}"
                    end

                    features << factory.feature(record.geom, record.id, obj)
                end

            end

            # Creates a text file and saves it to the report directory
            File.open("#{path}/json/#{file_name}.json", "w+") do |f|
                f.puts(RGeo::GeoJSON.encode(factory.feature_collection(features)).to_json)
            end

            # Convert GeoJSON to Shapefile with ogr2ogr
            `ogr2ogr -f "ESRI Shapefile" -fieldTypeToString Date,Time #{path}/shapefile/#{file_name}.shp "#{path}/json/#{file_name}.json"`

            shapefiles << file_name

            # Zip the files
            Zip::File.open("#{path}/zipped/#{project}_easements_to_fly_#{time_string}.zip", Zip::File::CREATE) do |zipfile|
                shapefiles.each do |shapefile|
                    [".shp", ".shx", ".dbf", ".prj"].each do |ext|
                        zipfile.add("#{shapefile}#{ext}", File.join("#{path}/shapefile/", "#{shapefile}#{ext}"))
                    end
                end
            end

            # output[:file] = "#{path}/zipped/easements_left_to_fly_#{time_string}.zip"
            # output[:file_name] = "easements_left_to_fly_#{time_string}.zip"

            # Create a new History record
            history = History.new
            history.message = "Generated Shapefile of #{project} Easements to Fly"
            history.action_type = "Exported Easements to Fly Shapefile"
            history.url = "#{path}/zipped/#{project}_easements_to_fly_#{time_string}.zip"
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

    # def self.find_utm_zones

    #     easement_id = []

    #     Easement.all.each do |easement|

    #         p easement.poly_id

    #         sql = "select count(*) from utms u where st_intersects(ST_GeomFromText('#{easement.geom.to_s}'), u.geom)"
    #         result = ActiveRecord::Base.connection.execute(sql)

    #         easement_id << easement.id if result[0]["count"] > 1
    #     end

    #     easement_id
    # end

    # def self.fix_utm_zones

    #     mismatched = []

    #     Easement.where(poly_id: ["665F4805007JY", "665A1295005RH", "665E3408006QN", "665A1206005TD", "6663220200G8L", "735E3407013FHA013FZ", "6663221301DJ2", "66632211016WV", "545D211601KXHA01KY3", "545E341401G0GA01G0J", "7311060100H3FA0002", "7311060200H3HA0006", "83142806011HY", "5414281801QHWA01QHX", "732D370700HHGB000o", "5433A71501HTXA01JXM"]).order(:poly_id).each do |easement|

    #         sql = "select id, zone, (st_area(st_intersection(ST_GeomFromText('#{easement.geom.to_s}'), u.geom))/st_area(ST_GeomFromText('#{easement.geom.to_s}'))) as area
    #         from utms u where st_intersects(ST_GeomFromText('#{easement.geom.to_s}'), u.geom)
    #         order by (st_area(st_intersection(ST_GeomFromText('#{easement.geom.to_s}'), u.geom))/st_area(ST_GeomFromText('#{easement.geom.to_s}'))) DESC"
            
    #         result = ActiveRecord::Base.connection.execute(sql)

    #         if result[0]["id"] != easement.utm_id

    #             mismatched << easement.poly_id 

    #             easement.update(
    #                 utm_zone: "#{result[0]["zone"]}N",
    #                 utm_id: result[0]["id"]
    #             )

    #             easement.tiles.update(
    #                 utm_zone: "#{result[0]["zone"]}N",
    #                 utm_id: result[0]["id"]
    #             )
    #         end

    #     end

    #     mismatched

    # end


    def self.find_covered_not_flown_easements

        # Iterate over rejected tiles and get easement
        # perform spatial query against footprints that cover it
        # Dissolve by Flight Date and check if Easement is covered


        # Create a new History record
        history = History.new
        history.action_type = "Find Coverage for Rejected Easements"
        history.creator = User.admins.first
        history.save

        output = ""

        # f = File.open("/media/sf_shared/audit/easements_covered_but_not_flown.csv", "w+")

        # f.puts "PolyID, State, Flight Date, Strip Frames\n"

        # easement_count = 0
        # footprint_count = 0

        # pluck all the rejected tile poly_ids
        rejected_poly_ids = RejectedTile.all.pluck(:poly_id).uniq

        # Find and iterate all the easements that have match polyids and are not marked as flown
        Easement.not_flown.where(poly_id: rejected_poly_ids).each do |easement|
        
            # Query against the Footprint geometry scoped based on the previous footprint id array
            # sql = "SELECT fp.id as fp_id, 
            sql = "SELECT fp.id as fp_id, 
                    fp.flight_date as fp_flight_date, 
                    fp.flown_by_id as fp_flown_by_id,
                    fp.camera_id as fp_camera_id,
                    fp.plane_id as fp_plane_id 
                    from easements e, footprints fp where st_intersects(e.geom, fp.geom) AND e.id = #{easement.id} AND fp.project='#{easement.project}' ORDER BY fp.flight_date DESC"
            results = ActiveRecord::Base.connection.execute(sql)

            footprints = {}

            results.each do |result|
                # p result

                if !footprints["#{result["fp_flight_date"]}_#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"] 
                    footprints["#{result["fp_flight_date"]}_#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"] = {
                        flight_date: result["fp_flight_date"],
                        fp_flown_by_id: result["fp_flown_by_id"],
                        fp_camera_id: result["fp_camera_id"],
                        fp_plane_id: result["fp_plane_id"],
                        ids: [result["fp_id"]]
                    }
                else 
                    footprints["#{result["fp_flight_date"]}_#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"][:ids] << result["fp_id"]
                end

            end

            # pp footprints

            # Begin dissolve and iteration

            footprints.each do |key, obj|
                DissolvedFootprint.footprints obj[:ids], easement.project

                sql = "SELECT ST_Contains(df.geom::geometry, e.geom::geometry) FROM dissolved_footprints df, easements e WHERE df.name = 'footprints'  AND e.id = #{easement.id}"
                results = ActiveRecord::Base.connection.execute(sql)

                # p results[0]

                if results[0]["st_contains"] == true
                    # p "UPDATE"

                    footprints = Footprint.exclude_geom.where(id: obj[:ids])

                    first_fp = footprints.first

                    # f.puts "#{easement.poly_id}, #{first_fp.state_name}, #{obj[:flight_date]}, '[#{footprints.pluck(:strip_frame).join(", ")}]' \n"
                    # output += "PolyID: #{easement.poly_id} ; Flight Date: #{obj[:flight_date]} - [#{obj[:ids].join(", ")}] \n"

                    at_date = first_fp.frame_center ? first_fp.frame_center.created_at : nil

                    p "Updating: #{easement.tiles.first.poly_id} - #{obj[:flight_date]} - #{obj[:ids].join(", ")}"

                    # Find and updat the tile
                    tile = easement.tiles.first
                    tile.update(flight_date: obj[:flight_date], at_start_date: at_date, at_done_date: at_date)
                    tile.easement.update(flight_date: obj[:flight_date])
                    tile.footprints << footprints
                    tile.update(filename: tile.build_filename)
                    tile.generate_median_flight_date_time

                    # find tile that was flown by same footprints and copy values
                    tile.update(flown_by_id: first_fp.flown_by_id, flown_by_name: first_fp.flown_by_name, plane_name: first_fp.plane_name, camera_name: first_fp.camera_name, plane_id: first_fp.plane_id, camera_id: first_fp.camera_id)

                    # add a check if the frame cente is already associated to the footprints
                    if first_fp.frame_center.present?
                        p "yah"
                        tile.update(at_start_date: first_fp.frame_center.created_at, at_done_date: first_fp.frame_center.created_at)
                    end

                    # easement_count += 1
                    # footprint_count += obj[:ids].size

                    history.easements << easement
                    history.tiles << tile
                    history.footprints << footprints

                    break

                end

            end
        end

        if history.easements.count > 0 || history.footprints.count > 0
            history.update(
                message: "Updated #{history.easements.count} Easements and associated #{history.footprints.count} Footprints"
            )
        else
            p "no easements or footprints, destroy history"
            history.delete
        end

        p "done"

        # p output
        # f.close

    end

    # def self.find_multiple_envelopes

    #     features = Array.new
    #     factory = RGeo::GeoJSON::EntityFactory.instance

    #     Easement.has_multiple_geom.each do |record|

    #         p record.poly_id

    #         # Get extent of all records
    #         extent = record.geom.envelope

    #         features << factory.feature(extent, record.id, {
    #             poly_id: record.poly_id,
    #             state: record.state_name,
    #             count: record.county_name
    #         })

    #         File.open("/media/sf_shared/2025/prep/multi_poly.json", "w+") do |f|
    #             f.puts(RGeo::GeoJSON.encode(factory.feature_collection(features)).to_json)
    #         end

    #     end

    #   rescue => e
    #     puts "Error: #{e.message}"
    #   ensure
    #     writer.close if writer && !writer.closed?
    # end

    # def self.build_state_list
    #     total = 0
    #     State.all.order(:abv).each do |state|
    #         if state.easements.count > 0
    #             p "#{state.abv} | #{state.easements.count} Sites | #{state.easements.sum(:acres).round(0).to_f} Acres"
    #             total += state.easements.sum(:acres).round(0)
    #         end
    #     end
    #     p "Total Acres: #{total.to_f}"
    # end

end
