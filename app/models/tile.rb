class Tile < ApplicationRecord
    include Concerns::Archive

    # Associations
    belongs_to :easement
    belongs_to :plane, optional: true
    belongs_to :camera, optional: true
    belongs_to :packing_slip, optional: true
    belongs_to :state
    belongs_to :project_state, class_name: 'State'
    belongs_to :county
    belongs_to :utm
    belongs_to :time_zone
    belongs_to :vector_metadatum, optional: true
    belongs_to :upload
    belongs_to :flown_by, class_name: 'Company', optional: true
    belongs_to :contract_award
    belongs_to :contract_rate, optional: true
    belongs_to :production_rate, class_name: 'ContractRate', optional: true
    belongs_to :flight_rate, class_name: 'ContractRate', optional: true
    has_one :batch_process_log
    has_one :imagery_path, as: :pathable
    has_many :rejected_tiles
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs
    has_many :tile_footprints
    has_many :footprints, -> { distinct }, through: :tile_footprints
    has_many :rejected_tile_footprints
    has_many :flight_times

    # Scopes
    # => Date Baed Status Scopes
    scope :sl,                      -> { where(project: "SL") }
    scope :nri,                      -> { where(project: "NRI") }
    scope :flown,                   -> { where.not(flight_date: nil) }
    scope :not_flown,               -> { where(flight_date: nil) }
    scope :county_flown,            -> { where.not(county_flown_date: nil) }
    scope :county_not_flown,        -> { where(county_flown_date: nil) }
    scope :county_due_set,          -> { where.not(county_due_date: nil) }
    scope :county_due_date_not_set, -> { where(county_due_date: nil) }
    scope :not_reported,            -> { where(report_date: nil) }
    scope :reported,                -> { where.not(report_date: nil) }
    scope :asi_accepted,            -> { where(asi_rejected_date: nil).where.not(flight_date: nil) }
    scope :asi_rejected,            -> { where.not(asi_rejected_date: nil) }
    scope :usda_accepted,           -> { where.not(usda_accepted_date: nil) }
    scope :not_usda_accepted,       -> { where(usda_accepted_date: nil) }
    scope :invoiced,                -> { where.not(invoiced_date: nil) }
    scope :not_invoiced,            -> { where(invoiced_date: nil) }
    scope :usda_rejected,           -> { where.not(usda_rejected_date: nil) }
    scope :not_usda_rejected,       -> { where(usda_rejected_date: nil) }
    scope :at_started,              -> { where.not(at_start_date: nil) }
    scope :not_at_started,          -> { where(at_start_date: nil, at_done_date: nil) }
    scope :at_in_process,           -> { where.not(at_start_date: nil).where(at_done_date: nil) }
    scope :at_done,                 -> { where.not(at_start_date: nil, at_done_date: nil) }
    scope :dumped,                  -> { where.not(dump_date: nil) }
    scope :not_dumped,              -> { where(dump_date: nil) }
    scope :ortho_processing,        -> { where.not(ortho_proc_date: nil) }
    scope :ortho_processed,         -> { where.not(ortho_proc_date: nil) }
    scope :not_ortho_processed,     -> { where(ortho_proc_date: nil) }
    scope :shipped,                 -> { where.not(ship_date: nil) }
    scope :not_shipped,             -> { where(ship_date: nil) }
    scope :has_rejections,          -> { includes(:rejected_tiles).where.not(rejected_tiles: { id: nil }) }
    scope :exclude_geom,            -> { select( Tile.attribute_names - ['geom'] ) }
    scope :covered,                 -> { where(covered: true) }
    scope :associated,              -> { where.not(associate_date: nil) }
    scope :ready_to_ship,           -> { where(ship_date: nil).where.not(flight_date: nil, at_done_date: nil, ortho_proc_date: nil, dump_date: nil) }

    # Validations
    validates_uniqueness_of :poly_id, allow_nil: false
    validates_uniqueness_of :filename, allow_nil: true
    validate :has_sl_camera
    validate :has_sl_plane
    validate :has_sl_flown_by
    validates :county_flown_date, presence: {if: [:flight_date?, :county_due_date?]}
    validates :county_due_date, presence: {if: [:flight_date?, :county_flown_date?]}

    # Callbacks
    before_save :set_pilot_and_so

    def set_pilot_and_so
        self.pilot = "NA" if self.pilot.nil?
        self.sensor_operator = "NA" if self.sensor_operator.nil?
    end

    def has_sl_camera
        if project == "sl" && !camera.sl
            errors.add(:camera, "is not a valid camera for NAIP")
        end
    end

    def has_sl_plane
        if project == "sl" && !plane.sl
            errors.add(:plane, "is not a valid plane for NAIP")
        end
    end

    def has_sl_flown_by
        if project == "sl" && !flown_by.sl
            errors.add(:flown_by, "is not a valid Company for NAIP")
        end
    end

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

    def dumped
        !dump_date.nil? ? true : false
    end

    def ortho_processing
        # where at_start_date and at_done_date is not nil
        !ortho_proc_date.nil? ? true : false
    end

    def shipped
        # where ship_date is not nil
        !ship_date.nil? ? true : false
    end

    def not_shipped
        # where ship_date is nil
        ship_date.nil? ? true : false
    end

    def ready_to_ship
        # check if the tile is flown, at_done, ortho_processing, dumped
        flown && at_done && ortho_processing && dumped && not_shipped
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
        # where ship_date is not nil
        !usda_accepted_date.nil? ? true : false
    end

    def usda_rejected
        # where ship_date is not nil
        !usda_rejected_date.nil? ? true : false
    end

    def shipped
        # where ship_date is not nil
        !ship_date.nil? ? true : false
    end

    def self.check_fully_flown_counties project="SL"

        completed_counties = []

        # Find the unique counties of all tiles that have been flown but county_flown_date is not set
        county_ids = Tile.flown.county_not_flown.not_shipped.pluck(:county_id).uniq

        p county_ids

        # iterate all the counties
        County.where(id: county_ids).each do |county|

            # Check if the total count for the county matches the tiles that have been marked as flown
            # The county must be completely flown and there must be at least 1 tile that does not have a county_flown_date
            if county.tiles.where(project: project).count == county.tiles.flown.where(project: project).count && county.tiles.flown.county_not_flown.not_shipped.where(project: project).count > 0
                # Get the max flight date from the tiles
                max_flight_date = county.tiles.flown.county_not_flown.not_shipped.where(project: project).order(:flight_date).last.flight_date
    
                # Get the due date by adding 30 days to the max flight date
                due_date = max_flight_date + 30.days

                # update the tiles with the max flight date and due date
                county.tiles.flown.county_not_flown.not_shipped.where(project: project).update(
                    county_flown_date: max_flight_date,
                    county_due_date: due_date
                )

                completed_counties << county
            end

        end

        # if there were updated counties then send email notifying 
        if completed_counties.size > 0

            html = '<style>#ready_to_ship_table {border-collapse: collapse;}#ready_to_ship_table th,#ready_to_ship_table td {padding: 2px 5px;border: 1px solid black;}</style>'
            html += "<p>The Following Counties have been marked as fully flown and have a set due date 30 Days from the latest Flight Date.</p>"

            html += '<table id="ready_to_ship_table" width="100%">'\
                '<tr>'\
                    '<th align="center">Project</th>'\
                    '<th align="center">State</th>'\
                    '<th align="center">County</th>'\
                    '<th align="center">Latest Flight Date</th>'\
                    '<th align="center">Due Date</th>'\
                    '<th align="center">Days Remaining</th>'\
                    '<th align="center">Number of Tiles</th>'\
                '</tr>'

            completed_counties.each do |county|

                county_due_dates = county.tiles.order(:county_due_date).pluck(:county_due_date).uniq

                county_due_dates.each do |cdd|

                    next if cdd.nil?

                    first = county.tiles.where(county_due_date: cdd).first
                    count = county.tiles.flown.county_flown.not_shipped.where(project: project).count

                    html += '<tr>'\
                        "<td align='center'>#{project}</td>"\
                        "<td align='center'>#{first.state_name}</td>"\
                        "<td align='center'><a href='#{Rails.application.routes.url_helpers.county_ready_to_ship_url(county_id: county.id, only_path: false, host: Rails.application.secrets.host)}'>#{county.name}</a></td>"\
                        "<td align='center'>#{first.county_flown_date.strftime("%m/%d/%Y")}</td>"\
                        "<td align='center'>#{first.county_due_date.strftime("%m/%d/%Y")}</td>"\
                        "<td align='center'>#{(first.county_due_date - Date.today).to_i}</td>"\
                        "<td align='center'>#{count}</td>"\
                    '</tr>'

                end
            end

            html += "</table>"

            p "size: #{html.size}"

            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Ready to Ship").users,
                subject: "#{project} Counties marked as Fully Flown",
                message: html,
                route: Rails.application.routes.url_helpers.ready_to_ship_url(only_path: false, host: Rails.application.secrets.host)
            })

        end

    end

    # Get the majority of associated flight dates
    def generate_median_flight_date_time

        # raise Exception, "Cannot generate median Flight Date Time for #{self.id}, No Footprints associated to Tile" if self.footprints.count == 0

        return false if self.footprints.count == 0

        flight_date_time_array = []

        # Now that there is a majority flight date (not time) then I need to get the 
        self.footprints.where(flight_date: self.flight_date).each do |footprint|

            next if footprint.flight_date_time.nil?

            # push to 
            flight_date_time_array << footprint.flight_date_time.to_f

        end

        if flight_date_time_array.length > 0


            if self.project == "SL"
    
                # Average the flight date
                self.median_flight_date_time = Time.at(flight_date_time_array[0]).utc

            else

                # Get the median Flight Date Time
                median = flight_date_time_array[flight_date_time_array.length / 2]
    
                # Average the flight date
                self.median_flight_date_time = Time.at(median).utc

            end
            
            if !self.save
                raise Exception, "Could not calculate Median Flight Date Time for Tile: #{self.poly_id} | #{self.errors.full_messages.to_sentence}"
            end

        else
            # raise Exception, "Could not calculat Median Flight Date Time for Tile: #{self.poly_id}"
        end

        return false

    end

    def generate_sun_angles date, num_days=0

        # gets the lat/lon from the associated easement
        # Calculates the sun angles
        # Find the first and last occurance of 30 degree 

        return if self.flown

        sa = SunAngle.new
        sa.from = date
        sa.to = date + num_days.days
        sa.min_sun_angle = Rails.application.secrets.min_sun_angle
        sa.lat = self.easement.latitude.to_f
        sa.lon = self.easement.longitude.to_f
        sa.timezone = self.time_zone.name

        # p "-----"
        # p sa

        result = sa.build

        result.each do |res|
            # p res

            # Set the start date and add/subtract 5 minutes to be safe
            start_date = res[:rise] + 2.minutes
            end_date = res[:set] - 2.minutes

            # Calculat the sun angle start and set based on the calculation
            sun_angle_start, azimuth = Solar.position(start_date, self.easement.longitude.to_f, self.easement.latitude.to_f)
            sun_angle_end, azimuth = Solar.position(end_date, self.easement.longitude.to_f, self.easement.latitude.to_f)

            # p "Sun Angles: #{sun_angle_start} - #{sun_angle_end}"

            # Check if the flight date already exists or not
            # => If so then update it
            if self.flight_times.find_by(flight_date: res[:date]).nil?
                self.flight_times.create(flight_date: res[:date], start_date: start_date, end_date: end_date)
            else
                self.flight_times.find_by(flight_date: res[:date]).update(start_date: start_date, end_date: end_date)
            end
        end
    end

    def set_contract_rate
        # checks if the flight date is set and 
        # => if so then will query out the contract rate and build the totals based on USDA acreage

        # only proceed if the flight date is set
        if self.flight_date

            p self.flight_date
            p self.flown_by
            p self.state.id
            p self.project

            # find the contract rate
            rates = ContractRate.find_rates self.flight_date, self.flown_by, self.state, self.project

            # If the tile has valid rates for each flight and production 
            if rates && rates[:production].present? && rates[:flight].present?

                flight_amount = rates[:flight][:cost].to_d * self.easements_acres
                production_amount = rates[:production][:cost].to_d * self.easements_acres

                sub_flight_amount = rates[:flight][:sub_cost] * self.easements_acres
                sub_production_amount = rates[:production][:sub_cost] * self.easements_acres

                # update the values
                self.update(
                    flight_rate_id: rates[:flight][:id],
                    flight_amount: flight_amount,
                    production_rate_id: rates[:production][:id],
                    production_amount: production_amount,
                    total_amount: flight_amount + production_amount,
                    sub_flight_cost: sub_flight_amount,
                    sub_production_cost: sub_production_amount,
                    sub_total_cost: sub_flight_amount + sub_production_amount,
                )

                # Return true to show it worked
                return true

            else

                # return false to show it failed
                return false
                
            end

        end
    end

    def self.generate user, project
        # queries Easements that do not have an associated tile
        # Creates the bounding box
        # Creates Tile with Easement Association

        # Get all easements that do not have a tile
        easements = Easement.left_outer_joins(:tiles).where( project: project, tiles: { id: nil } ).order(:id)

        count = 0
        ids = []

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin
                p "Tile Generation"
                p "Easement Count: #{easements.count}"

                # Iteramte the Easements
                easements.each do |easement|

                    # Insert the envelope of the easement into the tiles geometry and create the association
                    # => Convert Square Meters to Acres
                    sql = "INSERT INTO tiles (number, area, geom, easements_acres, poly_id, asi_block, usda_region, project, project_no, project_state_name, phase, easement_id, state_name, state_abv, county_name, utm_zone, county_id, state_id, project_state_id, utm_id, time_zone_id, contract_award_id, upload_id, created_at, updated_at) 
                            VALUES (1, (SELECT ST_Area(ST_Transform((SELECT ST_Envelope(geom::geometry) from easements where id=#{easement.id}), 269#{easement.utm.zone})) * 0.000247105), (SELECT ST_Envelope(geom::geometry) from easements where id=#{easement.id}), #{easement.acres},
                            '#{easement.poly_id}', '#{easement.asi_block}', '#{easement.usda_region}', '#{project}', '#{easement.project_no}', '#{easement.project_state_name}', '#{easement.phase}', #{easement.id}, '#{easement.state_name}', '#{easement.state_abv}', '#{easement.county_name.gsub("'"){"''"}}', '#{easement.utm_zone}', 
                            #{easement.county_id}, #{easement.state_id}, #{easement.project_state_id}, #{easement.utm_id}, #{easement.time_zone_id}, #{easement.contract_award_id}, #{easement.upload_id}, now()::timestamp, now()::timestamp)"
                    ActiveRecord::Base.connection.execute(sql)

                    ids << easement.id
                    count += 1
                end

                # Create a new History record
                history = History.new
                history.message = "Generated #{count} Tiles for #{project} from uploaded Easements"
                history.action_type = "Generated Tiles"
                history.creator = user
                history.save

                # add records to polymorphic association
                easements.each do |easement|
                    history.tiles << easement.tiles
                end

            rescue ActiveRecord::StatementInvalid => exception

                p "------------"
                p exception.message
                p "------------"

                # Create a new History record
                history = History.new
                history.message = "Failed to Create Tiles: #{exception.message}"
                history.action_type = "Create Tiles"
                history.creator = user
                history.save

            end

        end

        # Calculate Tile Flight times
        # => run as delayed job
        # Task.delay.update_flight_times

    end

    def self.set_dump_date params

        p params

        user = params[:user] || nil
        project = params[:project]

        job = Job.create(
            started_at: Time.now,
            active: true,
            message: "Iterating #{project} Tiffs in Tile Dump folder...",
            process_type: "Tile Dump",
            creator: user
        )

        # Stores variables for the job process
        process_success = false
        error_message = "Something went wrong. Contact Programming"
        count = 0
        error_count = 0

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # History
                history = History.new
                history.message = "Processing"
                history.action_type = "Tile Dump (#{project})"
                history.creator = user
                history.save

                path = Task.build params[:input_directory]

                # get the active counties in the states
                state = State.includes(:tiles).find(params[:state_id])

                error_filename = "Tile_Dump_Date_Errors - #{Date.today.strftime("%F")}.txt"
                error_path = "#{path}/#{error_filename}"

                # Create folder in directory to store errors
                error_file = File.new(error_path, "w")

                # iterate all files in folders
                Dir.glob("#{path}/*.tif").each do |file|

                    file_errors = []

                    filename = File.basename(file)
                    filename_without_extension = File.basename(file, '.tif')

                    # find the file in the database
                    tile = state.tiles.find_by(filename: filename_without_extension, project: project)

                    p "<><><><><><><>"
                    p filename
                    p tile
                    p "<><><><><><><>"

                    # Check if the tile has orhto processing or not
                    # then check if the tile dump date is set and if so skip it
                    if !tile
                        
                        missing_tile = state.tiles.find_by(filename: filename_without_extension)

                        if missing_tile && missing_tile.project != project
                            error_file.puts("#{filename} (#{project}) - Tile is in the wrong project folder\n")
                        else
                            error_file.puts("#{filename} - Tile does not exist in the database\n")
                        end
                        error_count += 1
                        next
                    elsif tile && !tile.ortho_processing
                        error_file.puts("#{filename} - Tile does not have an Ortho Processing Date set\n")
                        error_count += 1
                        next
                    elsif tile && !tile.dump_date.nil?
                        next
                    end

                    # return the listgeo response for validation
                    geotif_response = `listgeo "#{path}/#{filename}"`

                    # Check if the GTCitationGeoKey exists. If not then it hasn't been projected
                    if !geotif_response.include? "GTCitationGeoKey"
                        file_errors << "Headers does not contain GTCitationGeoKey. Needs to be projected"
                    end

                    # Validate if the tile is present
                    if tile.present?

                        # check the tile's status dates
                        file_errors << "does not have a Flight Date" if tile.flight_date.nil?
                        file_errors << "does not have a AT Done Date" if tile.at_done_date.nil?
                        file_errors << "does not have a Ortho Processing Date" if tile.ortho_proc_date.nil?

                        # Check if UTM Zone in the projection to match against the tile
                        if !geotif_response.include? "NAD_1983_UTM_Zone_#{tile.utm_zone}"
                            file_errors << "Invalid UTM Zone, should be zone #{tile.utm_zone}"
                        end

                    end

                    # Get the gdalinfo response
                    gdalinfo_response = `gdalinfo "#{path}/#{filename}"`

                    # Check if gadalinfo doesn't contain the 4th band
                    if !gdalinfo_response.include? "Band 4"
                        file_errors << "Does not have a 4th band listed in the gdalinfo response"
                    end

                    # check for errors
                    if file_errors.size > 0
                        file_errors.each do |error|
                            error_file.puts("#{filename} - #{error}\n")
                            error_count += 1
                        end
                    elsif tile.present?
                        # Set the Tile Dump Date if no errors
                        tile.update(dump_date: Time.now)
                        history.tiles << tile

                        # Add to the total
                        count += 1
                    end

                end

                # close the file
                error_file.close

                message = ""

                # If no errors then delete file
                if error_count == 0
                    File.delete(error_path) if File.exists? error_path
                end

                # Check the error output and if no errors then delete the text file
                if error_count > 0 && count > 0
                    message = "#{count} Tiles were marked as Dumped  for #{state.name} in #{params[:input_directory]}"
                elsif error_count == 0 && count > 0
                    message = "#{count} Tiles were marked as Dumped for #{state.name} in #{params[:input_directory]}"
                elsif error_count == 0 && count == 0
                    message = "No Tiles were found for #{state.name} in #{params[:input_directory]}"
                elsif error_count > 0 && count == 0
                    message = "No Tiles were found for #{state.name} in #{params[:input_directory]}"
                else

                end

                error_message = ""
                message = ""
                subject = ""

                if error_count > 0
                    # error_message = "and #{error_count} errors were recorded at #{error_path} "
                    error_message = "#{error_count} errors were detected and added to #{params[:input_directory]}#{error_filename}."
                end

                p "---------"
                p count
                p error_count
                p "---------"

                if count > 0
                    subject = "Tile Dump Completed#{error_count > 0 ? " with Errors" : ""}"
                    message = "#{count} Tiles were marked as Dumped for #{state.name} in #{params[:input_directory]}.#{error_message}"
                elsif count == 0 && error_count > 0
                    subject = "Tile Dump Failed"
                    message = "No Tiles were updated for #{state.name} in #{params[:input_directory]}#{error_message}"
                elsif count == 0 && error_count == 0
                    subject = "Tile Dump Failed"
                    message = "No Tiles were updated and no errors were detected for #{state.name} in #{params[:input_directory]}. Please verify the correct State and Tile Dump folder."
                end

                # add the tiles to the history
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
                    users: MailGroup.find_by(name: "Tile Dump").users | [user],
                    subject: subject,
                    message: message
                })

                process_success = true

            rescue Exception => exception
                
                Rails.logger.error "Tile Dump Error: #{exception.message}"
                p "-----------"
                # p exception.backtrace.count
                exception.backtrace.each do |x|
                    next if !x.include? "tile.rb"
                    x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
                   p [$1,$2,$4]
                end
                p "-----------"
            end
        end
        

        # # Run if the process failed
        # if !process_success

        #     # Log and send email
        #     Mailbox.ship({
        #         users: MailGroup.find_by(name: "Tile Dump").users | [current_user],
        #         subject: "#{project} Tile Dump Failed",
        #         message: "#{project} Tile Dump Failed, error encountered is listed below: <br/><br/>#{error_message}".html_safe
        #     })

        #     # Update the Job
        #     job.update(
        #         finished_at: Time.now,
        #         active: false,
        #         success: false,
        #         message: "#{project} Final Delivery Failed",
        #         error_message: error_message
        #     )
        # end

        # return

        # # Copy the file to the server
        # # Get the folder name by converting the current time to seconds
        # folder = Time.now.to_i

        # path = "#{Rails.root}/assets/tile_dump/#{folder}"

        # # Create a folder if it doesn't exist
        # FileUtils.mkdir_p(path)
        # FileUtils.mkdir("#{path}/original")

        # File.write("#{path}/original/#{File.basename(params[:file].original_filename)}", File.read(params[:file].path))

        # # Start a Transaction Block
        # ActiveRecord::Base.transaction do
        #     begin

        #         File.open(params[:file].path, "r", row_sep: :auto) do |f|
        #             f.each_line do |line|

        #                 filename = File.basename(line.strip, ".tif")

        #                 tile = Tile.flown.at_done.ortho_processed.find_by(filename: filename)

        #                 p "-----"
        #                 p filename
        #                 p tile
        #                 p "-----"

        #                 if tile.present?
        #                     if tile.dump_date.nil?
        #                         output[:count] += 1
        #                         tile.update(dump_date: Time.now)
        #                     else
        #                         output[:skip] += 1
        #                     end
        #                 else
        #                     # Abort and rollback
        #                     output[:errors] = ["File #{line} does not exist in the database."]
        #                     raise ActiveRecord::Rollback
        #                 end

        #             end
        #         end

        #         # Log and send email
        #         Mailbox.ship({
        #             users: MailGroup.find_by(name: "Tile Dump").users | [user],
        #             subject: "Tile Dump Completed",
        #             message: "<p>#{output[:count]} Tiles were marked as Dumped, #{output[:skip]} were skipped as they already had a Dump Date assigned.</p>"
        #         })

        #     rescue ActiveRecord::StatementInvalid => exception
        #         output[:errors] << exception.message
        #     end
        # end

        # if output[:errors].count == 0

        #     message = "Updated Tile Dump Date on #{output[:count]} tiles"

        #     # check if any were skipped
        #     if output[:skip] > 0
        #         message += ", and skipped #{output[:skip]} tiles because they already have a Dump Date set"
        #     end

        #     output[:message] = message

        #     # Log and send email
        #     Mailbox.ship({
        #         users: [user],
        #         subject: "Tile Dump Failed",
        #         message: message
        #     })

        #     # History
        #     history = History.new
        #     history.message = message
        #     history.action_type = "Tile Dump"
        #     history.creator = params[:user]
        #     history.save
        # else
        #     output[:pass] = false
        # end

        # output
    end

    # Update the filenames
    def self.update_filename
        # find the tiles that have been flown
        Tile.flown.each do |tile|
            tile.update(
                filename: self.build_filename
            )
        end
    end

    def build_filename
        if self.project == "SL"
            "ortho_#{self.state.abv}_15_#{self.poly_id}_#{self.easement.flight_date.strftime("%Y%m%d")}"
        elsif self.project == "NRI"
            "ortho_#{self.easement.poly_id}_15_#{self.easement.flight_date.strftime("%Y%m%d")}"
        end
    end

    def self.generate_cutfile params
        # Iterate all tiles within the selected counties that are not shipped
        # Create Text File
        # Build the filename and save to tile
        # Calculate Extents for geometry (in NAD83 and contained UTM zone)
        # Write filename and extents to text file
        # Save text file to assets directory and return copy to user

        # create an Error array to hold any messages
        output = {
            pass: false,
            errors: [],
            count: 0,
            file: nil
        }

        user = params[:user]
        project = params[:project]

        # Get the folder name by converting the current time to seconds
        folder = Time.now.to_i

        path = "#{Rails.root}/assets/cutfile/#{folder}/"

        # Create a folder if it doesn't exist

        FileUtils.mkdir_p(path) unless File.directory?(path)
        FileUtils.mkdir("#{path}/original") unless File.directory?("#{path}/original")

        # Create upload instance to track the easements created
        upload = Upload.create(
            folder_path: path,
            upload_type: "Tile",
            uploader: user
        )

        # Get State
        state = State.find(params[:state_id])

        # Set the formated date to a string to be reused
        time_string = Time.now.strftime("%Y%m%d")

        # Set the file name
        # => NH_170714_cutfile
        file_name = "#{state.abv}_#{time_string}_cutfile.txt"

        output[:file] = "#{path}/original/#{file_name}"
        output[:file_name] = file_name
        output[:count] = 0

        tiles = []

        # Creates a text file and saves it to the report directory
        File.open("#{path}/original/#{file_name}", "w+") do |f|

            County.where(id: params[:counties]).order(name: :asc).each do |county|

                # Iterate the county tiles that have not been shipped yet
                county.tiles.flown.at_done.not_dumped.not_shipped.where(project: project).each do |tile|

                    # Set the ortho processing date and status
                    # => only set it if the Tile Ortho Proc Date is nil
                    if tile.ortho_proc_date.nil?
                        tile.update(
                            ortho_proc_date: params[:ortho_processing_date]
                        )
                        tiles << tile
                    end

                    # Get the extents
                    # => Couldn't get RGEO working so going direct
                    sql = "SELECT ST_XMin(ST_Transform(geom::geometry, 269#{tile.utm.zone.to_s.rjust(2, '0')})) as x_min, 
                                  ST_XMax(ST_Transform(geom::geometry, 269#{tile.utm.zone.to_s.rjust(2, '0')})) as x_max, 
                                  ST_YMin(ST_Transform(geom::geometry, 269#{tile.utm.zone.to_s.rjust(2, '0')})) as y_min, 
                                  ST_YMax(ST_Transform(geom::geometry, 269#{tile.utm.zone.to_s.rjust(2, '0')})) as y_max FROM tiles where id = #{tile.id}"

                    result = ActiveRecord::Base.connection.execute(sql)

                    # Print the file name and the extents to the file
                    # => ortho_NH_15_6614281000Z0L_1_180330 336296.681079572 4824462.59339204 338353.602356894 4827096.64310826
                    f.puts("#{tile.filename} #{result[0]["x_min"]} #{result[0]["y_min"]} #{result[0]["x_max"]} #{result[0]["y_max"]}")

                    output[:count] += 1

                end

            end

        end


        if output[:errors].count == 0
            output[:pass] = true

            # Copy cutfile to P drive
            FileUtils.cp("#{path}/original/#{file_name}", "#{Rails.application.secrets.cutfile_folder}/#{project}/#{file_name}")

            # Create a new History record
            history = History.new
            history.message = "Created #{project} Cut File for #{output[:count]} Tiles"
            history.action_type = "Create Cut File (#{project})"
            history.creator = user
            history.save

            # add records to polymorphic association
            history.uploads << upload
            history.tiles = tiles

            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Ortho Processing").users | [user],
                subject: "Cut File was generated",
                message: "<p>Cut File #{file_name} was generated for #{output[:count]} Tiles. A Copy is stored in #{Rails.application.secrets.cutfile_folder_p_path}\\#{project}\\#{file_name}</p>",
                route: Rails.application.routes.url_helpers.show_timeline_url(history.id, only_path: false, host: Rails.application.secrets.host)
            })

            # send out ready to ship notifier
            Tile.ready_to_ship_notifier

        # else
        #     upload.tiles.destroy_all
        #     FileUtils.rm_rf(path)
        #     upload.destroy
        end

        # Return output to controller
        output

    end

    def self.generate_tile_status_from_content_file params

        output = {
            pass: false,
            message: nil,
            count: 0,
            errors: [],
            result: []
        }

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                file_name = File.basename(params[:file].original_filename, '.txt')

                File.open(params[:file].path, "r") do |f|
                    f.each_line do |line|

                        if line[0...5] == "ortho"
                            arr = line.split(' ')

                            filename = arr[0].gsub(".tif", "")

                            tile = Tile.find_by(filename: filename)

                            if tile.nil?
                                obj = {
                                    filename: filename,
                                    match_db: false
                                }
                            else
                                obj = {
                                    filename: filename,
                                    match_db: true,
                                    project: tile.project,
                                    flown: tile.flown,
                                    ortho_processing: tile.ortho_processing,
                                    shipped: tile.shipped,
                                    at_started: tile.at_started,
                                    at_done: tile.at_done,
                                    flight_date: tile.flight_date,
                                    dump_date: tile.dump_date,
                                    ortho_proc_date: tile.ortho_proc_date,
                                    ship_date: tile.ship_date,
                                    asi_rejected_date: tile.asi_rejected_date,
                                    usda_rejected_date: tile.usda_rejected_date,
                                    at_start_date: tile.at_start_date,
                                    at_done_date: tile.at_done_date
                                }
                            end

                            output[:result] << obj

                        end

                    end
                end

            rescue ActiveRecord::StatementInvalid => exception
                output[:errors] = exception.message
            end
        end

        if output[:errors].count == 0
            output[:pass] = true
        end

        if output[:result].count > 0
            output[:result] = output[:result].sort_by { |r| r["filename"] }
        end

        output

    end

    def self.ready_to_ship_notifier project="SL"

        p "READY TO SHIP NOTIFIER - #{Time.now}"

        overdue = []
        due_within_7_days = []
        due_within_14_days = []
        due_within_30_days = []

        current_date = Date.today

        # Find the unique counties of all tiles that have been flown but county_flown_date is not set
        County.exclude_geom.includes(:tiles).where(id: Tile.flown.county_flown.not_shipped.where(project: project).order(:state_name, :county_name).pluck(:county_id).uniq).each do |county|

            county_due_dates = county.tiles.where(project: project).order(:county_due_date).pluck(:county_due_date).uniq

            county_due_dates.each do |cdd|

                next if cdd.nil?

                first = county.tiles.where(county_due_date: cdd, project: project).first
    
                # check if overdue
                is_overdue = current_date >= first.county_due_date
    
                # Get the number of days
                days_til_due = (first.county_due_date - current_date).to_i
    
                # Check the days til due and assign to correct array
                if is_overdue
                    overdue << county
                elsif days_til_due <= 7
                    due_within_7_days << county
                elsif days_til_due <= 14
                    due_within_14_days |= [county.state_id]
                else
                    due_within_30_days |= [county.state_id]
                end


            end

        end

        html = "<ul>"
        if overdue.length > 0
            html += "<li>Counties Overdue: #{overdue.length}</li>"
        end
        if due_within_7_days.length > 0
            html += "<li>Counties Due with 7 Days: #{due_within_7_days.length}</li>"
        end
        if due_within_14_days.length > 0
            html += "<li>Counties Due with 14 Days: #{due_within_14_days.length}</li>"
        end
        if due_within_30_days.length > 0
            html += "<li>Counties Due with 30 Days: #{due_within_30_days.length}</li>"
        end
        html += "</ul>"

        if overdue.length == 0 && due_within_7_days.length == 0 && due_within_14_days.length == 0 && due_within_30_days.length == 0
            html = "<p>No Counties have Tiles that are marked as ready to ship</p>"
        end

        # Log and send email
        Mailbox.ship({
            users: MailGroup.find_by(name: "Ready to Ship").users,
            subject: "Daily Ready to Ship Report",
            message: html,
            route: Rails.application.routes.url_helpers.ready_to_ship_url(host: Rails.application.secrets.host)
        })
    end

    def self.usda_rejection params
        p params 

        # create an Error array to hold any messages
        output = {
            pass: false,
            errors: [],
            count: 0
        }

         # Start a Transaction Block
         ActiveRecord::Base.transaction do
            begin

                # Get the folder name by converting the current time to seconds
                folder = Time.now.to_i

                path = "#{Rails.root}/assets/usda_rejection/#{folder}"

                # Create a folder if it doesn't exist
                FileUtils.mkdir_p(path) unless File.directory?(path)

                file = params[:file]

                if File.extname(file.original_filename) == ".txt" 
                    # Move that file to the server
                    FileUtils.mv file.tempfile, "#{path}/#{file.original_filename}"
                else
                    output[:errors] << "File must be a .txt File!"
                    raise ActiveRecord::Rollback
                end

                # Create upload instance to track the easements created
                upload = Upload.create(
                    folder_path: path,
                    upload_type: "USDA Rejection",
                    uploader: params[:user]
                )

                txt = Dir.glob("#{path}/*.txt").first

                if txt.empty?
                    output[:errors] << "Could not find text file to upload"
                    FileUtils.rm_rf(path)
                    raise ActiveRecord::Rollback
                end

                tiles = []
        
                File.open(txt, "r") do |f|
                    f.each_line do |line|

                        p line.strip

                        # Get the tile, only should be one
                        tile = Tile.where(poly_id: line.strip).first

                        p "Tile ID: #{tile.id}"

                        if tile.present?
                            if params[:clear_notes]
                                notes = nil
                            elsif params[:notes].present?
                                if tile.notes.present?
                                    notes = [tile.notes, params[:notes]].join(', ')
                                else 
                                    notes = params[:notes]
                                end
                            else
                                notes = tile.notes
                            end

                            p "---------"
                            p notes

                            # Set the Status
                            if params[:status] == "reject"
                                tile.update(usda_rejected_date: Time.now, notes: notes)
                            elsif params[:status] == "clear"
                                tile.update(usda_rejected_date: nil, notes: notes)
                            else
                                output[:errors] << "Unknown Status supplied: #{params[:status]}"
                                FileUtils.rm_rf(path)
                                raise ActiveRecord::Rollback
                            end

                            output[:count] += 1
                            tiles << tile
                        end
                    end
                end

                if output[:errors].count == 0 && output[:count] > 0
                    output[:pass] = true

                    # Create a new History record
                    history = History.new
                    if params[:status] == 'reject'
                        history.message = "Set USDA Rejected Date for #{output[:count]} Tiles!"
                        history.action_type = "Set USDA Rejected Date"
                    elsif params[:status] == 'clear'
                        history.message = "Cleared USDA Rejected Date for #{output[:count]} Tiles!"
                        history.action_type = "Clear USDA Rejected Date"
                    end
                    history.creator = params[:user]
                    history.save
            
                    # add records to polymorphic association
                    history.uploads << upload
                    history.tiles = tiles
                end

            rescue ActiveRecord::StatementInvalid => exception
                output[:errors] = exception.message
            end
        end

        # Return output to controller
        output

    end

    def self.generate_wip_by_state_export

        p "GENERATE WIP BY STATE EXPORT - #{Time.now}"

        # Build a CSV and write it to the P Drive of the 

        file_name = "wip_by_state_#{DateTime.now.strftime('%Y_%m_%d_%H_%M_%S')}"

        CSV.open("#{Rails.application.secrets.wip_by_state_folder}#{file_name}.csv", "wb") do |csv|

            # Build the headers
            csv << [
                "State Name",
                "County Name",
                "Total Acres", 
                "Tiles Count", 
                # Costs
                "Flown Costs", 
                "AT Done Costs", 
                "Ortho Processing Costs", 
                "Dumped Costs", 
                "Shipped Costs", 
                "Invoiced Costs", 
                # Acres
                "Flown Acres", 
                "Flown Acres Percentage", 
                "AT Done Acres", 
                "Ortho Processing Acres", 
                "Ortho Processing Acres Percentage", 
                "Dumped Acres", 
                "Shipped Acres", 
                "Invoiced Acres",
                # Counts
                "Flown Count", 
                "AT Done Count", 
                "Ortho Processing Count", 
                "Dumped Count", 
                "Shipped Count", 
                "Invoiced Count",
            ]

            # calculate a large buffer for 
            start_date = Date.strptime("#{Rails.application.secrets.project_year}-01-01", "%F") - 1.year
            end_date = start_date + 3.years # add some buffer in case it goes over 1 year

            # # track totals
            # total_acres = 0.0;
            # total_counties = 0
            # total_tiles = 0
            # # cost
            # total_flown_cost = 0.0;
            # total_at_done_cost= 0.0
            # total_ortho_proc_cost= 0.0
            # total_dump_cost= 0.0
            # total_shipped_cost= 0.0
            # total_invoiced_cost= 0.0
            # # acres
            # total_flown_acres= 0.0
            # total_at_done_acres= 0.0
            # total_ortho_proc_acres= 0.0
            # total_dump_acres= 0.0
            # total_shipped_acres= 0.0
            # total_invoiced_acres= 0.0
            # # counts
            # total_flown_count = 0
            # total_at_done_count = 0
            # total_ortho_proc_count = 0
            # total_dump_count = 0
            # total_shipped_count = 0
            # total_invoiced_count = 0

            State.active.order(:abv).each do |state|

                # calculate the wip by state counties
                state.sl_wip_by_state_counties( start_date, end_date).each do |result|

                    # Desstruct the result object
                    name, 
                    county_name,
                    acres,
                    total,
                    flown_cost,
                    at_done_cost, 
                    ortho_processing_cost,
                    dumped_cost,
                    shipped_cost,
                    invoiced_cost,
                    flown_acres,
                    flown_percentage,
                    at_done_acres,
                    ortho_processing_acres,
                    orthos_percentage, 
                    dumped_acres, 
                    shipped_acres,
                    invoiced_acres,
                    flown_count, 
                    at_done_count, 
                    ortho_processing_count, 
                    dumped_count,
                    shipped_count,
                    invoiced_count = result.values_at(
                        :name, 
                        :county_name,
                        :acres,
                        :total,
                        :flown_cost,
                        :at_done_cost, 
                        :ortho_processing_cost,
                        :dumped_cost,
                        :shipped_cost,
                        :invoiced_cost,
                        :flown_acres,
                        :flown_percentage,
                        :at_done_acres,
                        :ortho_processing_acres,
                        :orthos_percentage, 
                        :dumped_acres, 
                        :shipped_acres,
                        :invoiced_acres,
                        :flown_count, 
                        :at_done_count, 
                        :ortho_processing_count, 
                        :dumped_count,
                        :shipped_count,
                        :invoiced_count
                    )

                    # Write to CSV
                    csv << [
                        name, 
                        county_name,
                        acres,
                        total,
                        flown_cost,
                        at_done_cost, 
                        ortho_processing_cost,
                        dumped_cost,
                        shipped_cost,
                        invoiced_cost,
                        flown_acres,
                        "#{flown_percentage}%",
                        at_done_acres,
                        ortho_processing_acres,
                        "#{orthos_percentage}%", 
                        dumped_acres, 
                        shipped_acres,
                        invoiced_acres,
                        flown_count, 
                        at_done_count, 
                        ortho_processing_count, 
                        dumped_count,
                        shipped_count,
                        invoiced_count
                    ]

                end

            end
        end
    
        p "done"
    end

    def self.compare_tile_dump params

        output = {
            message: "Something went wrong",
            records: []
        }

        state = State.exclude_geom.find(params[:state_id])

        filenames = []

        File.open(params[:file].path, "r") do |f|
            f.each_line do |line|
                # p line.strip.gsub(".tif", "")
                filenames << line.strip.gsub(".tif", "")

            end
        end

        records = []

        if params[:project] == "SL"
            records = state.tiles.sl.exclude_geom.where.not(filename: filenames).or(state.tiles.sl.exclude_geom.where(filename: nil)).order(:county_name)
        elsif params[:project] == "NRI"
            records = state.tiles.nri.exclude_geom.where.not(filename: filenames).or(state.tiles.nri.exclude_geom.where(filename: nil)).order(:county_name)
        elsif params[:project] == "NAIP"
            records = state.doqqs.exclude_geom.where.not(filename: filenames).or(state.doqqs.exclude_geom.where(filename: nil)).order(:county_name)
        end
        
        if records.size > 0
            output[:records] = records
            output[:message] = "Found #{records.size} Matches that were not in File"
            output[:state] = true
        else
            output[:message] = "All Matches Found!"
            output[:state] = true
        end

        output
    end

    # # def self.flight_crew_report companies, states, date_flown_from, date_flown_end

    #     result = []

    #     Tile.flown.where(state_id: states.pluck(:id), flown_by_id: companies.pluck(:id), flight_date: date_flown_from..date_flown_end)
    #         .select(:flown_by_name, :pilot, :sensor_operator, :state_name).distinct
    #             .to_a.sort { |a, b| [a[:flown_by_name], a[:state_name], a[:pilot], a[:sensor_operator]] <=> [b[:flown_by_name], b[:state_name], b[:pilot], b[:sensor_operator]] }.each do |group|

    #                 # p group

    #         obj = {
    #             flown_by_name: group[:flown_by_name],
    #             state_name: group[:state_name],
    #             pilot: group[:pilot],
    #             sensor_operator: group[:sensor_operator],
    #             flown: 0,
    #             # asi_accepted: 0,
    #             # asi_rejected: 0,
    #             # usda_accepted: 0,
    #             # usda_rejected: 0,
    #             # accepted: 0,
    #             rejected: 0
    #         }

    #         Tile.flown.where(
    #             flown_by_name: group[:flown_by_name],
    #             state_name: group[:state_name],
    #             pilot: group[:pilot],
    #             sensor_operator: group[:sensor_operator],
    #             flight_date: date_flown_from..date_flown_end,
    #         ).each do |tile|

    #             # if (tile.easement.rejected_tiles.count > 0)
    #             #     p "TILE"
    #             #     p tile.id
    #             # end
                
    #             obj[:flown] += 1

    #             # obj[:flown] += 1
    #             # obj[:asi_accepted] += tile.asi_accepted ? 1 : 0
    #             # # obj[:asi_rejected] += tile.easement.rejected_tiles.count
    #             # obj[:usda_accepted] += tile.usda_accepted ? 1 : 0
    #             # # obj[:usda_rejected] += tile.usda_rejected ? 1 : 0
    #         end

    #         RejectedTile.where(
    #             flown_by_name: group[:flown_by_name],
    #             state_name: group[:state_name],
    #             pilot: group[:pilot],
    #             sensor_operator: group[:sensor_operator],
    #             flight_date: date_flown_from..date_flown_end,
    #         ).each do |tile|

    #             p tile.id

    #             # obj[:accepted] += 1
    #             obj[:rejected] += 1
    #         end

    #         result << obj

    #     end

    #     p "------------"
    #     p result
    #     p "------------"

    #     result

    # end

    def find_covered ignore_flight_date=nil

        output = {
            message: "Something went wrong",
            result: [],
            pass: false
        }

        # check that the ignore flight date is a valid date field
        if ignore_flight_date
            if ignore_flight_date.class == Date
                ignore_flight_date = ignore_flight_date.strftime("%F")
            else
                return {
                    message: "Supplied Flight Date to Exclude is not a valid Date",
                    result: [],
                    pass: false
                }
            end
        end

        # Create an empty array to store footprints to exclude from the query
        exclude_footprints = []

        # Check if the tile has any rejected tiles
        if self.rejected_tiles.count > 0
            # build a list of the Footprint Original IDs in the RejectedTileFootprint layer to exclude in the query
            exclude_footprints = RejectedTileFootprint.where(tile_id: self.id).map {|r| r.original_footprint_id}
        end

        # Query against the Footprint geometry scoped based on the previous footprint id array
        # sql = "SELECT fp.id as fp_id, 
        sql = "SELECT 
                fp.strip_frame as fp_strip_frame,
                fp.id as fp_id,
                fp.flight_date as fp_flight_date, 
                fp.flown_by_id as fp_flown_by_id,
                fp.flown_by_name as fp_flown_by_name,
                fp.flown_by_alias as fp_flown_by_alias,
                fp.camera_id as fp_camera_id,
                fp.camera_name as fp_camera_name,
                fp.plane_id as fp_plane_id,
                fp.plane_name as fp_plane_name,
                fp.upload_id as fp_upload_id
                from easements e, footprints fp where st_intersects(e.geom, fp.geom) AND fp.id != ALL('{#{exclude_footprints.join(",")}}'::int[]) 
                    AND e.id = #{self.easement.id} AND fp.project='NRI/SL' 
                    ORDER BY fp.flight_date ASC, fp.strip_frame ASC"

        # sql to exclude the footprints that have been flagged by the rejected tile
        # AND fp.id != ALL('{#{exclude_footprints.join(",")}}'::int[]) 

        results = ActiveRecord::Base.connection.execute(sql)

        footprints = {}

        results.each do |result|
            p "------"
            p result["fp_flight_date"]
            p "------"

            # check if the 
            next if result["fp_flight_date"] == ignore_flight_date

            key = "#{result["fp_flight_date"]}_#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"

            if !footprints[key]
                footprints[key] = {
                    flight_date: result["fp_flight_date"],
                    # fp_rejection: exclude_footprints.include?(result["fp_id"]),
                    fp_flown_by_id: result["fp_flown_by_id"],
                    fp_camera_id: result["fp_camera_id"],
                    fp_plane_id: result["fp_plane_id"],

                    flown_by_name: result["fp_flown_by_name"],
                    flown_by_alias: result["fp_flown_by_alias"],
                    camera_name: result["fp_camera_name"],
                    plane_name: result["fp_plane_name"],

                    upload_id: result["fp_upload_id"],
                    upload_date: Upload.find(result["fp_upload_id"]).created_at,
                    ids: [result["fp_id"]],
                    strip_frames: [{value: result["fp_strip_frame"], rejection: exclude_footprints.include?(result["fp_id"])}]
                }
            else 
                # footprints[key][:fp_rejection] = exclude_footprints.include?(result["fp_id"]) if !footprints[key][:fp_rejection]
                footprints[key][:strip_frames] << {value: result["fp_strip_frame"], rejection: exclude_footprints.include?(result["fp_id"])}
                footprints[key][:ids] << result["fp_id"]
            end

        end

        # pp footprints

        footprints.each do |key, obj|
            DissolvedFootprint.footprints obj[:ids], "NRI/SL"

            sql = "SELECT ST_Contains(df.geom::geometry, e.geom::geometry) FROM dissolved_footprints df, easements e WHERE df.name = 'footprints'  AND e.id = #{self.easement.id}"
            results = ActiveRecord::Base.connection.execute(sql)

            # p results[0]

            if results[0]["st_contains"] == true
                # p "------------"
                # p obj

                output[:result] << obj

            end

        end

        if output[:result].size > 0
            output[:message] = "Found #{output[:result].size} Flight Dates that cover Easement."
            output[:pass] = true
        end

        return output

    end

    def self.notify_easements_with_multiple_coverages

        p "NOTIFY EASEMENTS WITH MULTIPLE COVERAGES - #{Time.now}"

        if Tile.covered.count > 0

            tiles = Tile.covered.order(:poly_id)

            # build a list of affected poly_ids
            tile_list = tiles.map {|tile| "<li>#{tile.poly_id}</li>"}.join("")

            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Easements with Multiple Coverages").users,
                subject: "Daily Duplicate Overlapping Footprint Reminder",
                message: "There are #{tiles.count} Easements were marked as covered by multiple Flight Dates. Please click link below to reivew and set the correct Footprint association. This is a daily reminder that will continue until the Easements are updated.<hr/>#{tile_list}<ul></ul>",
                route: Rails.application.routes.url_helpers.easements_with_multiple_coverages_url(only_path: false, host: Rails.application.secrets.host)
            })

            # send out email
            # Rails.application.secrets.multiple_covered_users.each do |user|
            #     record = User.find_by(user)
            #     next if record.nil?
            #     PostmasterMailer.notify(record, "There are #{tiles.count} Easements were marked as covered by multiple Flight Dates. Please click link below to reivew and set the correct Footprint association. This is a daily reminder that will continue until the Easements are updated.<hr/>#{tile_list}<ul></ul>".html_safe, "USDA #{Rails.application.secrets.project_year}: Daily Duplicate Overlapping Footprint Reminder - #{Time.now.strftime("%m/%d/%Y")}", Rails.application.routes.url_helpers.easements_with_multiple_coverages_url(only_path: false, host: Rails.application.secrets.host)).deliver
            # end

        end
    end

    def self.update_footprint_association tile, upload, user

        # p "update_footprint_association"
        # p tile.footprints.count
        # p tile.footprints.pluck(:upload_id).uniq.first != upload.id

        # Find the footprints that intersect the selected tile's easement boundary
        # Dissassociate the current footprints from the easement
        # associate the selected footprints
        # update the tile attributes based on footprint and frame center associations

        # Check if the currently selected tile is the one provided
        # => If so then do not query out the footprints
        if tile.footprints.pluck(:upload_id).uniq.first == upload.id
            # skip updating the easement since it's valid
            tile.update(covered: false)
            return true
        else

            # Find the footprints that intersect the selected easement
            # Reject the current tile and footprints

            # find the footprints
            new_footprints = Footprint.where(project: "NRI/SL").where("st_intersects(footprints.geom, ST_GeomFromText('#{tile.easement.geom.to_s}')) and footprints.upload_id = '#{upload.id}'")

            # p "-----"
            # p new_footprints.count
            # p "-----"

            if new_footprints.count == 0
                p "No Match"
                return false
            end

            # Create a new History record
            history = History.new
            history.action_type = "Covered Easement Updated"
            history.creator = user
            history.save

            # Check if the tile needs to be rejected or not
            # if the tile doesn't have a flight date then don't reject it
            if tile.flown
                # Reject the tile
                Rejection.reject_tiles [tile.poly_id], tile.flight_date, history, true

                # Reselect the tile since it has been rejected
                tile = Tile.find(tile.id)
            end

            # Iterate the new_footprints and associate them to the tile
            first = new_footprints.first

            # Update the Easement flight date
            tile.easement.update(flight_date: first.flight_date)

            # Update each tile and reset the asi_rejected_date back to nil
            tile.update!(
                flight_date: first.flight_date,
                asi_rejected_date: nil,
                camera_name: first.camera_name,
                camera_id: first.camera_id,
                plane_name: first.plane_name,
                plane_id: first.plane_id,
                flown_by_alias: first.flown_by_alias,
                flown_by_name: first.flown_by_name,
                flown_by_id: first.flown_by_id,
                pilot: first.pilot_name,
                sensor_operator: first.camera_operator_name,
                covered: false,
                filename: tile.build_filename,
                vector_metadatum_id: first.vector_metadatum_id,
                associate_date: Date.today
            )

            # update the contract rates
            tile.set_contract_rate

            # add associations to history
            history.easements | [tile.easement]
            history.tiles | [tile]
            history.footprints << new_footprints

            # update the history message
            history.message = "Updated Tile (#{tile.poly_id}) with Flight Date of #{first.flight_date.strftime("%m/%d/%Y")}"
            history.save

            # check if the footprint Frame Centers are set
            if FrameCenter.where(footprint: new_footprints).count > 0
                tile.update(at_start_date: first.frame_center.created_at, at_done_date: first.frame_center.created_at)
            end

            # Update the footprint associations
            tile.footprints << new_footprints

            # update the associated footprints
            new_footprints.update(associated: true)

            return true
        end

        # Remove the covered status so it falls off the Easements with Multiple Coverages report
        # self.update(covered: false)

    end

    # def self.fix_dump_date
    #     Tile.dumped.each do |tile|
    #         if tile.ortho_proc_date.nil?
    #             tile.update(dump_date: nil)
    #         elsif tile.dump_date < tile.ortho_proc_date
    #             tile.update(dump_date: tile.ortho_proc_date + 1.days)
    #         end
    #     end
    # end

    # def self.find_missing_at_dates

    #     arr = []

    #     Tile.flown.not_at_started.includes(footprints: [:frame_center]).each do |tile|
    #         # flight_date = tile.footprint.pluck(:flight_date)

    #         next if tile.footprints.first.frame_center.nil?

    #         create_date = tile.footprints.first.frame_center.created_at

    #         tile.update(at_start_date: create_date, at_done_date: create_date)

    #         arr << tile.poly_id
    #     end

    #     arr
    # end

    # def self.update_tile_association

    #     tile = Tile.find_by(poly_id: '6663229800GXR')
    #     footprints = Footprint.where(id: [11202, 11201, 11203])
        
    #     first = footprints.first
        
    #     tile.update(flight_date: first.flight_date, flown_by_id: first.flown_by_id, flown_by_name: first.flown_by_name, plane_name: first.plane_name, camera_name: first.camera_name, plane_id: first.plane_id, camera_id: first.camera_id, pilot: first.pilot_name, sensor_operator: first.camera_operator_name)
    #     tile.easement.update(flight_date: first.flight_date)
    #     tile.footprints = []
    #     tile.footprints << footprints
    #     tile.update(filename: tile.build_filename)
    #     tile.generate_median_flight_date_time
        
    #     frame_centers = FrameCenter.where(footprint: footprints)
    #     at_date = nil
        
    #     # Check to make sure all the associated footprints have frame centers
    #     tile.footprints.includes(:frame_center).all.each do |fp|
    #         if fp.frame_center.nil?
    #             at_date = nil    
    #             break
    #         end
        
    #         if at_date.nil? || at_date < fp.frame_center.created_at
    #             at_date = fp.frame_center.created_at
    #         end
    #     end
        
    #     tile.update(at_start_date: at_date, at_done_date: at_date) if at_date.present?

    # end
    
    # def self.update_multiple_tile_association

    #     obj = [{poly_id: "6652KY06005G0", flight_date: "2022-05-22"},{poly_id: "6652KY010050N", flight_date: "2022-05-23"},{poly_id: "5452KY1601KVS", flight_date: "2022-06-19"},{poly_id: "6652KY1000Y3W", flight_date: "2022-05-23"}, {poly_id: "5452KY1901P62", flight_date: "2022-06-19"},{poly_id: "6652KY05005C8", flight_date: "2022-06-19"},{poly_id: "6652KY05005BC", flight_date: "2022-06-19"},{poly_id: "6652KY040058T", flight_date: "2022-05-23"}, {poly_id: "6652KY05005C9", flight_date: "2022-05-23"}, {poly_id: "5452KY1401G8V", flight_date: "2022-06-19"},{poly_id: "5452KY1901QRD", flight_date: "2022-06-19"}]
    #     project = "SL"

    #     obj.each do |record|

    #         tile = Tile.includes(:easement).find_by(poly_id: record[:poly_id])

    #         footprints = Footprint.where(flight_date: record[:flight_date], project: tile.project).where("st_intersects(ST_GeomFromText('#{tile.easement.geom.to_s}'), footprints.geom)")

    #         # p "Poly_id: "
    #         footprints.update_all(notes: record[:poly_id])

    #         first = footprints.first
            
    #         tile.update(flight_date: first.flight_date, flown_by_id: first.flown_by_id, flown_by_name: first.flown_by_name, plane_name: first.plane_name, camera_name: first.camera_name, plane_id: first.plane_id, camera_id: first.camera_id, pilot: first.pilot_name, sensor_operator: first.camera_operator_name)
    #         tile.easement.update(flight_date: first.flight_date)
    #         tile.footprints = []
    #         tile.footprints << footprints
    #         tile.update(filename: tile.build_filename)
    #         tile.generate_median_flight_date_time
        
    #         frame_centers = FrameCenter.where(footprint: footprints)
    #         at_date = nil
            
    #         # Check to make sure all the associated footprints have frame centers
    #         tile.footprints.includes(:frame_center).all.each do |fp|
    #             if fp.frame_center.nil?
    #                 at_date = nil    
    #                 break
    #             end
            
    #             if at_date.nil? || at_date < fp.frame_center.created_at
    #                 at_date = fp.frame_center.created_at
    #             end
    #         end

    #         tile.update(at_start_date: at_date, at_done_date: at_date) if at_date.present?

    #     end

    # end


    def self.count_geometries

        # Iterate unflown tiles
        # check if tiles have mutiple geoemtries

        ids = []

        Easement.not_flown.each do |easement|
            
            # sql = "SELECT ST_Contains(df.geom::geometry, e.geom::geometry) FROM dissolved_footprints df, easements e WHERE df.name = 'footprints'  AND e.id = #{self.easement.id}"

            sql = "SELECT ST_NumGeometries(e.geom::geometry) as count from easements e where e.id = #{easement.id}"
            results = ActiveRecord::Base.connection.execute(sql)

            if results[0]["count"] > 1
                p "Easement: #{easement.poly_id} : #{results[0]["count"]}"
                ids << easement.poly_id
            end

        end

        ids

    end

    def self.update_rejection_type
        RejectedFrameCenter.where(rejection_type: "Auto Rejection during Frame Center upload").each do |rfc|
            rfc.rejected_footprint.rejected_tiles.each do |rt|
                rt.update(rejection_type: "Auto Reject")
            end
        end
    end

    def self.find_potential_coverages
        # Iterate all not flown tiles
        # Check if they have multiple geometries or not
        # check if they have partial coverage or not
        # check if they have rejections
            # => check if it was manual or automatic
            # => if automatic then return the sun angle


        f = File.open("/media/sf_shared/2024/Audit/overview.csv", "w+")
        f.puts "PolyID, State, MultipleGeom, Coverage, RejectionCount\n"

        c = File.open("/media/sf_shared/2024/Audit/potential_coverages.csv", "w+")
        c.puts "PolyID, State, FlightDate, StripFrame, FlownBy\n"

        r = File.open("/media/sf_shared/2024/Audit/potential_rejections.csv", "w+")
        r.puts "PolyID, State, FlightDate, RejectedDate, RejectionType, RejectedSunAngle\n"

        multiple_coverage_poly_ids = Tile.count_geometries

        Tile.includes(:rejected_tiles).not_flown.each do |tile|

            rejected_count = tile.rejected_tiles.count
            coverage = "No"

            # Check if muliple
            multiple = multiple_coverage_poly_ids.include?(tile.poly_id) ? "Yes" : "No"

            # Check if has partial coverage
            sql = "select id, strip_frame, flight_date, flown_by_name from footprints fp where st_intersects(ST_GeomFromText('#{tile.geom.to_s}'), fp.geom)"

            # sql = "SELECT ST_Intersects(ST_GeomFromText('#{footprint.geom.to_s}', ST_GeomFromText('#{tile.geom.to_s}');"
            result = ActiveRecord::Base.connection.execute(sql)

            if result.count > 0
                list = []
                result.each do |r|
                    c.puts "#{tile.poly_id}, #{tile.state_name}, #{r["flight_date"]}, #{r["strip_frame"]}, #{r["flown_by_name"]}\n"
                end
                coverage = "Yes"

            end

            # check if has rejections
            if rejected_count > 0
                
                tile.rejected_tiles.includes(rejected_footprints: [:rejected_frame_center]).each do |rt|

                    # if rt.rejected_footprints
                    rejection_type = rt.rejection_type

                    if rejection_type == "Auto Reject"
                        rt.rejected_footprints.each do |rf|
                            r.puts "#{rt.poly_id}, #{rt.state_name}, #{rt.flight_date}, #{rt.rejected_date}, #{rt.rejection_type}, #{rf.rejected_frame_center.sun_angle}\n"
                        end
                    else
                        r.puts "#{rt.poly_id}, #{rt.state_name}, #{rt.flight_date}, #{rt.rejected_date}, #{rt.rejection_type}, NA\n"
                    end

                end
            end

            f.puts "#{tile.poly_id}, #{tile.state_name}, #{multiple}, #{coverage}, #{rejected_count}\n"
        end

        f.close
        c.close
        r.close

        p "Done"

    end

    # def self.clear_psn

    #     filenames = ["ortho_GA_15_5443101701L63_20240331", "ortho_VA_15_6633A71101667_20240325", "ortho_TN_15_66474102004SW_20240323", "ortho_WV_15_663D4710011BV_20240325"]

    #     filenames.each do |filename|

    #         tile = Tile.find_by(filename: filename)

    #         tile.update(ship_date: nil)

    #         tile.county.tiles.where.not(id: tile.id).update(
    #             ortho_proc_date: nil,
    #             ship_date: nil
    #         )

    #     end

    # end


    def self.update_invoice_date
        PackingSlip.invoiced.each do |ps|
            p ps.name
            ps.tiles.update(invoiced_date: ps.invoice.invoice_date)
        end
    end

    def self.associate_to_footprints

        poly_id = "5452KY2001V17"
        footprint_ids = [37414,37415,37416,37417]

        # get the tile
        tile = Tile.find_by(poly_id: poly_id)

        # find the footprints
        footprints = Footprint.where(id: footprint_ids)

        # Update all the footprints to reflect the associated project
        # footprints.update_all(sl: true, associated: true)

        # Associate to the tiles
        tile.footprints = []
        tile.footprints = footprints

        current_time = Time.now
        tile.update(at_start_date: current_time, at_done_date: current_time)
        tile.generate_median_flight_date_time

    end

end
