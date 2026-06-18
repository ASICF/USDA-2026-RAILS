class History < ApplicationRecord
    include Concerns::Archive
    include PgSearch

    # Associations
    belongs_to :creator, class_name: 'User'
    has_many :historic_assocs
    # has_many :airborne_digital_sensors, through: :historic_assocs, source: :historicable, source_type: 'AirborneDigitalSensor'
    has_many :cameras, through: :historic_assocs, source: :historicable, source_type: 'Camera'
    has_many :companies, through: :historic_assocs, source: :historicable, source_type: 'Company'
    has_many :easements, through: :historic_assocs, source: :historicable, source_type: 'Easement'
    has_many :footprints, through: :historic_assocs, source: :historicable, source_type: 'Footprint'
    has_many :frame_centers, through: :historic_assocs, source: :historicable, source_type: 'FrameCenter'
    has_many :packing_slips, through: :historic_assocs, source: :historicable, source_type: 'PackingSlip'
    has_many :planes, through: :historic_assocs, source: :historicable, source_type: 'Plane'
    has_many :rejected_tiles, through: :historic_assocs, source: :historicable, source_type: 'RejectedTile'
    has_many :rejected_footprints, through: :historic_assocs, source: :historicable, source_type: 'RejectedFootprint'
    has_many :rejected_frame_centers, through: :historic_assocs, source: :historicable, source_type: 'RejectedFrameCenter'
    # has_many :rejected_airborne_digital_sensors, through: :historic_assocs, source: :historicable, source_type: 'RejectedAirborneDigitalSensor'
    has_many :tiles, through: :historic_assocs, source: :historicable, source_type: 'Tile'
    has_many :doqqs, through: :historic_assocs, source: :historicable, source_type: 'Doqq'
    has_many :users, through: :historic_assocs, source: :historicable, source_type: 'User'
    has_many :uploads, through: :historic_assocs, source: :historicable, source_type: 'Upload'
    has_many :web_log_uploads, through: :historic_assocs, source: :historicable, source_type: 'WebLogUpload'
    has_many :batch_processes, through: :historic_assocs, source: :historicable, source_type: 'BatchProcess'
    has_many :photo_indices, through: :historic_assocs, source: :historicable, source_type: 'PhotoIndex'

    # Callbacks
    before_create :add_creator_to_search_terms

    # Adds the creator to the search terms so they are always findable
    def add_creator_to_search_terms
        self.search_terms = "#{self.search_terms} #{self.creator.first_name} #{self.creator.last_name}".squish
    end

    # Make the search_terms field searchable
    # pg_search_scope :search, against: :search_terms, order_within_rank: "histories.created_at DESC"
    pg_search_scope :search, against: :search_terms, associated_against: {
        historic_assocs: :search_terms
    }, order_within_rank: "histories.created_at DESC"

    def upload
        uploads.first
    end

    def batch_process
        batch_processes.first
    end

    def self.build_export user, type="all"

        job = Job.create(
            started_at: Time.now,
            message: "Building Excel Tables...",
            active: true,
            process_type: "Excel Export",
            creator: user
        )

        begin

            # Create the new excel file and intiailizte the workbook
            package = Axlsx::Package.new
            wb = package.workbook

            # Global Styles
            header_background = wb.styles.add_style(bg_color: "5c8a5c", fg_color: "FFFFFF")

            if type == "all"

                # Buffered Easements
                wb.add_worksheet(name: "Buffered Easements") do |sheet|
                    sheet.add_row [
                        "ID",
                        "PolyID",
                        "OriginalPolyID",
                        "Project",
                        "ProjectNo",
                        "ProjectState",
                        "Phase",
                        "FlightDate",
                        "Acres",
                        # "BufferedAcres",
                        "StartDate",
                        "EndDate",
                        "ASIBlock",
                        "Status",
                        "USDARegion",
                        "Latitude",
                        "Longitude",
                        "County",
                        "State",
                        "UTMZone"], style: header_background
                    Easement.includes(:utm).order(:poly_id).each do |record|
                        r = sheet.add_row [
                            record.id,
                            record.poly_id,
                            record.original_poly_id,
                            record.project,
                            record.project_no,
                            record.project_state_name,
                            record.phase,
                            record.flight_date.nil? ? "" : record.flight_date,
                            record.acres,
                            # record.buffer_acres,
                            record.start_date,
                            record.end_date,
                            record.asi_block,
                            record.status,
                            record.usda_region,
                            record.latitude,
                            record.longitude,
                            record.county_name,
                            record.state_name,
                            "#{record.utm.zone}N"
                        ], style: [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]
                        
                        # Catch and update the poly_id so it's always a string
                        r.cells[1].type = :string
                        r.cells[1].value = record.poly_id
                        r.cells[2].type = :string
                        r.cells[2].value = record.original_poly_id

                    end
                end

            end

            # Tiles
            wb.add_worksheet(name: "Tiles") do |sheet|
                sheet.add_row [
                    "ID",
                    "FileName",
                    "Project",
                    "ProjectNo",
                    "Phase",
                    "ASIBlock",
                    "USDARegion",
                    "PSN",
                    "Area",
                    "EasementAcres",
                    "PolyID",
                    "LineID",
                    "ATBlock",
                    "FlightDate",
                    "CountyFlownDate",
                    "CountyDueDate",

                    "MedianFlightDate",
                    "ReportDate",
                    "OrthoProcDate",
                    "TileDumpDate",
                    "ATStartDate",
                    "ATDoneDate",
                    "ShipDate",
                    "InvoicedDate",
                    "USDAAcceptDate",

                    "County",
                    "State",
                    "UTMZone",
                    "FlownByCompany",
                    "Pilot",
                    "SensorOperator",
                    "PlaneName",
                    "CameraName",
                    "Notes",

                    "ReviewDesc",
                    "FlightPrice",
                    "ProductionPrice",
                    "TotalPrice",
                    "SubFlightCost",
                    "SubProductionCost",
                    "SubTotalCost",
                    "CreatedAt",
                    "UpdatedAt"
                ], style: header_background
                Tile.includes(:easement, :camera, :plane, :flown_by, :packing_slip, :utm).order("easements.poly_id DESC").each do |record|
                    r = sheet.add_row [
                        record.id,
                        record.filename,
                        record.project,
                        record.project_no,
                        record.phase,
                        record.asi_block,
                        record.usda_region,
                        record.psn,
                        record.area,
                        record.easements_acres.to_f,
                        record.poly_id,
                        record.line_id,
                        record.at_block,
                        record.flight_date,
                        record.county_flown_date,
                        record.county_due_date,

                        record.median_flight_date_time,
                        record.report_date,
                        record.ortho_proc_date,
                        record.dump_date,
                        record.at_start_date, 
                        record.at_done_date,
                        record.ship_date,
                        record.invoiced_date,
                        record.usda_accepted_date,

                        record.county_name,
                        record.state_name,
                        record.utm_zone, 
                        record.flown_by_name, 
                        record.pilot, 
                        record.sensor_operator, 
                        record.plane_name,
                        record.camera_name,
                        record.notes,

                        record.review_desc,
                        record.flight_amount,
                        record.production_amount,
                        record.total_amount,
                        record.sub_flight_cost,
                        record.sub_production_cost,
                        record.sub_total_cost,
                        record.created_at,
                        record.updated_at
                    ], 
                    style: [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]

                    # Catch and update the poly_id so it's always a string
                    r.cells[10].type = :string
                    r.cells[10].value = record.poly_id
                end
            end

            # Rejected Tiles
            wb.add_worksheet(name: "Rejected Tiles") do |sheet|
                sheet.add_row [
                    "ID",
                    "RejectedDate",
                    "RejectionReportedDate",
                    "RejectionType",
                    "Project",
                    "Number",
                    "FileName",
                    "Project",
                    "ProjectNo",
                    "Phase",
                    "ASIBlock",
                    "USDARegion",
                    "PSN",
                    "Area",
                    "PolyID",
                    "LineID",
                    "ATBlock",
                    "FlightDate",
                    "CountyFlownDate",
                    "CountyDueDate",
                    "MedianFlightDate",
                    "ReportDate",
                    "OrthoProcDate",
                    "TileDumpDate",
                    "ATStartDate",
                    "ATDoneDate",
                    "ShipDate",
                    "USDAAcceptDate",
                    "InvoicedDate",
                    "County",
                    "State",
                    "UTMZone",
                    "FlownByCompany",
                    "Pilot",
                    "SensorOperator",
                    "PlaneName",
                    "CameraName",
                    "Notes",
                    "ReviewDesc",
                    "FlightPrice",
                    "ProductionPrice",
                    "TotalPrice",
                    "SubFlightCost",
                    "SubProductionCost",
                    "SubTotalCost",
                    "CreatedAt",
                    "UpdatedAt"
                ], style: header_background
                RejectedTile.order("poly_id DESC").each do |record|
                    r = sheet.add_row [
                        record.id,
                        record.rejected_date,
                        record.rejection_report_date,
                        record.rejection_type,
                        record.project,
                        record.number,
                        record.filename,
                        record.project,
                        record.project_no,
                        record.phase,
                        record.asi_block,
                        record.usda_region,
                        record.psn,
                        record.area,
                        record.poly_id,
                        record.line_id,
                        record.at_block,
                        record.flight_date,
                        record.county_flown_date,
                        record.county_due_date,
                        record.median_flight_date_time,
                        record.report_date,
                        record.ortho_proc_date,
                        record.dump_date,
                        record.at_start_date, 
                        record.at_done_date,
                        record.ship_date,
                        record.usda_accepted_date,
                        record.invoiced_date,
                        record.county_name,
                        record.state_name,
                        record.utm_zone, 
                        record.flown_by_name, 
                        record.pilot, 
                        record.sensor_operator, 
                        record.plane_name,
                        record.camera_name,
                        record.notes,
                        record.review_desc,
                        record.flight_amount,
                        record.production_amount,
                        record.total_amount,
                        record.sub_flight_cost,
                        record.sub_production_cost,
                        record.sub_total_cost,
                        record.created_at,
                        record.updated_at,
                    ], style: [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]

                    # Catch and update the poly_id so it's always a string
                    r.cells[15].type = :string
                    r.cells[15].value = record.poly_id
                end
            end

            if type == "all"

                # Footprints
                wb.add_worksheet(name: "Footprints") do |sheet|
                    sheet.add_row [
                        "ID",
                        "Project",
                        "FlightDate",
                        "FlightDateTime",
                        "OriginalStripFrame",
                        "StripFrame",
                        "FlownBy",
                        "Pilot",
                        "SensorOperator",
                        "State",
                        "County",
                        "UTM Zone"
                    ], style: header_background
                    Footprint.all.each do |record|
                        sheet.add_row [
                            record.id,
                            record.project,
                            record.flight_date,
                            record.flight_date_time,
                            record.original_strip_frame,
                            record.strip_frame,
                            record.flown_by_name,
                            record.pilot_name,
                            record.camera_operator_name,
                            record.state_name,
                            record.county_name,
                            record.utm_zone,  
                        ], style: [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]
                    end
                end

                # Rejected Footprints
                wb.add_worksheet(name: "Rejected Footprints") do |sheet|
                    sheet.add_row [
                        "ID",
                        "OriginalID",
                        "RejectedDate",
                        "RejectionType",
                        "Project",
                        "FlightDate",
                        "FlightDateTime",
                        "OriginalStripFrame",
                        "StripFrame",
                        "FlownBy",
                        "Pilot",
                        "SensorOperator",
                        "State",
                        "County",
                        "UTM Zone"
                    ], style: header_background
                    RejectedFootprint.all.each do |record|
                        sheet.add_row [
                            record.id,
                            record.original_id,
                            record.rejected_date,
                            record.rejection_type,
                            record.project,
                            record.flight_date,
                            record.flight_date_time,
                            record.original_strip_frame,
                            record.strip_frame,
                            record.flown_by_name,
                            record.pilot_name,
                            record.camera_operator_name,
                            record.state_name,
                            record.county_name,
                            record.utm_zone,  
                        ], style: [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]
                    end
                end

                # Frame Centers
                wb.add_worksheet(name: "Frame Centers") do |sheet|
                    sheet.add_row [
                        "ID",
                        "StripFrame",
                        "Project",
                        "GPSTime",
                        "X",
                        "Y",
                        "Z",
                        "Omega",
                        "PHI",
                        "Kappa",
                        "SunAngle",
                        "FlightDate",
                        "HasSunAngleError",
                        "FlownBy",
                        "Camera",
                        "Plane",
                        "Latitude",
                        "Longitude",
                        "County",
                        "State"
                    ], style: header_background
                    FrameCenter.all.each do |record|
                        sheet.add_row [
                            record.id,
                            record.strip_frame,
                            record.project,
                            record.gpstime,
                            record.x,
                            record.y,
                            record.z,
                            record.omega,
                            record.phi,
                            record.kappa,
                            record.sun_angle.to_f,
                            record.flight_date,
                            record.sun_angle_error,
                            record.flown_by_name,
                            record.camera_name,
                            record.plane_name,
                            record.latitude,
                            record.longitude,
                            record.county_name,
                            record.state_name
                        ], style: [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]
                    end
                end

                # Rejected Frame Centers
                wb.add_worksheet(name: "Rejected Frame Centers") do |sheet|
                    sheet.add_row [
                        "ID",
                        "OriginalId",
                        "RejectedDate",
                        "RejectionType",
                        "Project",
                        "StripFrame",
                        "GPSTime",
                        "X",
                        "Y",
                        "Z",
                        "Omega",
                        "PHI",
                        "Kappa",
                        "SunAngle",
                        "FlightDate",
                        "HasSunAngleError",
                        "FlownBy",
                        "Camera",
                        "Plane",
                        "Latitude",
                        "Longitude",
                        "County",
                        "State"
                    ], style: header_background
                    RejectedFrameCenter.all.each do |record|
                        sheet.add_row [
                            record.id,
                            record.original_id,
                            record.rejected_date,
                            record.rejection_type,
                            record.project,
                            record.strip_frame,
                            record.gpstime,
                            record.x,
                            record.y,
                            record.z,
                            record.omega,
                            record.phi,
                            record.kappa,
                            record.sun_angle.to_f,
                            record.flight_date,
                            record.sun_angle_error,
                            record.flown_by_name,
                            record.camera_name,
                            record.plane_name,
                            record.latitude,
                            record.longitude,
                            record.county_name,
                            record.state_name
                        ], style: [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]
                    end
                end

                wb.add_worksheet(name: "Contract Awards") do |sheet|
                    sheet.add_row [
                        "ID",
                        "Project",
                        "Project NO",
                        "State",
                        "Flight Cost",
                        "Production Cost",
                        "Total Cost",
                        "Start Date",
                        "End Date"
                    ], style: header_background
                    ContractAward.includes(:state).each do |record|
                        r = sheet.add_row [
                            record.id,
                            record.project,
                            record.project_no,
                            record.state.name,
                            record.flight_amount.to_f,
                            record.production_amount.to_f,
                            record.amount.to_f,
                            record.start_date,
                            record.end_date
                        ], style: [nil,nil,nil,nil,nil,nil,nil,nil]
                    end
                end

                wb.add_worksheet(name: "Contract Rates") do |sheet|
                    sheet.add_row [
                        "ID",
                        "Project",
                        "Project NO",
                        "State",
                        "Company",
                        "Phase",
                        "Cost",
                        "SubCost",
                        "Start Date",
                        "End Date"
                    ], style: header_background
                    ContractRate.includes(:state).each do |record|
                        r = sheet.add_row [
                            record.id,
                            record.project,
                            record.project_no,
                            record.state.name,
                            record.company_alias,
                            record.phase,
                            record.cost.to_f,
                            record.sub_cost.to_f,
                            record.start_date,
                            record.end_date
                        ], style: [nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]
                    end
                end

            end

            # Write to output
            path = Rails.root.join('assets', 'excel_export')
            Dir.mkdir(path) unless File.directory?(path)
            timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
            package.serialize("#{path}/USDA #{Rails.application.secrets.project_year} Report (#{timestamp}).xlsx")

            job.update(
                finished_at: Time.now,
                active: false,
                success: true,
                message: "Successfully generated Excel Export."
            )

            # Create a new History record
            history = History.new
            history.message = type == "all" ? "Successfully generated Full Excel Export" : "Succesfully generated Tile Excel Export"
            history.url = "#{path}/USDA #{Rails.application.secrets.project_year} Report (#{timestamp}).xlsx"
            history.action_type = "Excel Export"
            history.creator = user
            history.save

            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Excel Export").users | [user],
                subject: "Excel Export",
                message: "#{user.full_name} Successfully generated #{type == "all" ? "Full" : "Tile"} Excel Export. It can be downloaded with the link below.",
                route: Rails.application.routes.url_helpers.show_timeline_url(history.id, only_path: false, host: Rails.application.secrets.host)
            })

            # PostmasterMailer.notify(user, "Successfuylly generated Excel Export. It can be downloaded with the link below.", "USDA #{Rails.application.secrets.project_year}: Excel Export - #{Time.now.strftime("%m/%d/%Y")}", Rails.application.routes.url_helpers.show_timeline_url(history.id, only_path: false, host: Rails.application.secrets.host)).deliver

        rescue => error
            
            # Update the Job
            job.update(
                finished_at: Time.now,
                active: false,
                success: false,
                message: "Import Failed",
                upload: nil,
                error_message: error.message
            )

            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Errors").users | [user],
                subject: "Excel Export Error",
                message: "Error while generating Excel Export due to error below.<br/>#{error.message}".html_safe
            })

            # PostmasterMailer.notify(user, "Error while generating Excel Export due to error below.<br/>#{error.message}".html_safe, "USDA #{Rails.application.secrets.project_year}: Excel Export - #{Time.now.strftime("%m/%d/%Y")}").deliver     

        end

    end

end
