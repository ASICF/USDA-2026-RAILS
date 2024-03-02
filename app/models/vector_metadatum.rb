class VectorMetadatum < ApplicationRecord

    # Associations
    belongs_to :state
    has_many :tiles
    has_many :doqqs
    has_many :footprints
    has_many :web_log_summary
    has_many :web_logs
    has_many :imagery_paths, as: :pathable

    # Scopes
    scope :sl, -> { where(project: "SL") }
    scope :naip, -> { where(project: "NAIP") }
    scope :provisional_active, -> { where(provisional_date: nil) }
    scope :provisional_finished, -> { where.not(provisional_date: nil) }
    scope :production_active, -> { where(production_date: nil) }
    scope :production_finished, -> { where.not(production_date: nil) }

    def associations
        self.project == "SL" ? self.tiles : self.doqqs
    end

    def self.update_associations

        # Update NAIP associations
        VectorMetadatum.naip.each do |vm|
            vm.doqqs << Doqq.where(flight_date: vm.flight_date)
        end

        # Update SL associations
        VectorMetadatum.sl.each do |vm|
            vm.tiles << Tile.where(state_id: 5, flight_date: vm.flight_date)
        end

    end

    def self.update_production_export
        VectorMetadatum.naip.update(production_date: "2022-10-26", production_due_date: "2022-10-26")
        VectorMetadatum.where(state_name: "Rhode Island").update(production_date: "2022-10-31", production_due_date: "2022-11-02")

        VectorMetadatum.where(state_name: "Rhode Island").each do |vm|
            Tile.where(state_id: 5, flight_date: vm.flight_date).update(vector_metadatum: vm)
        end
    end

    def self.query project, date_from, date_to, export=nil

        # Parse the dates
        date_from = Time.parse(date_from).utc.beginning_of_day
        date_to = Time.parse(date_to).utc.end_of_day

        results = []

        # Get the Provisional VMs
        VectorMetadatum.where(project: project, provisional_date: date_from..date_to).each do |vm|
            vm.footprints.select(:strip_frame, :flight_date).each do |fp|
                results << {
                    type: "Provisional",
                    exposure_id: fp.strip_frame,
                    service_name: vm.service_name,
                    flight_date: fp.flight_date.strftime("%m/%d/%Y"),
                    upload_date: vm.provisional_date.strftime("%m/%d/%Y"),
                    due_date: vm.provisional_due_date.strftime("%m/%d/%Y"),
                }
            end
        end

        # Get the Production VMs
        vms = VectorMetadatum.where(project: project, production_date: date_from..date_to)

        if project == "SL"
            vms.each do|vm|
                vm.tiles.select(:poly_id, :flight_date).each do |tile|
                    results << {
                        type: "Production",
                        exposure_id: tile.poly_id,
                        service_name: "#{vm.state.abv}_PRODUCTION_4B_ALL",
                        flight_date: tile.flight_date.strftime("%m/%d/%Y"),
                        upload_date: vm.production_date.strftime("%m/%d/%Y"),
                        due_date: vm.production_due_date.strftime("%m/%d/%Y"),
                    }
                end
            end
        else
            vms.each do|vm|
                vm.doqqs.select(:qq_apfo_name, :flight_date).each do |doqq|
                    results << {
                        type: "Production",
                        exposure_id: doqq.qq_apfo_name,
                        service_name: "#{vm.state.abv}_PRODUCTION_4B_ALL",
                        flight_date: doqq.flight_date.strftime("%m/%d/%Y"),
                        upload_date: vm.production_date.strftime("%m/%d/%Y"),
                        due_date: vm.production_due_date.strftime("%m/%d/%Y"),
                    }
                end
            end
        end

        if export
            CSV.generate(headers: true) do |csv|
                csv << ["Service", "ExposureID", "AcquisitionDate", "UploadDate"]
                results.each do |record|
                    csv << [
                        record[:service_name],
                        record[:exposure_id],
                        record[:flight_date],
                        record[:upload_date],
                    ]
                end
            end
        else

            if results.size == 0
                return {
                    state: false,
                    message: "No Records found"
                }
            end

            return {
                state: true,
                message: "Successfully returned #{results.size} Records",
                results: results
            }
        end

    end

    def self.check_if_path_exists input_directory

        path = Task.build input_directory

        if !path || !File.directory?(path)
            return false
        end

        return true
    end

    def provisional_export input_directory, upload_date=Time.now, user

        count = 0

        response ={
            pass: false,
            message: "Something went wrong"
        }
    
        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                path = Task.build input_directory

                p path

                if !path
                    raise Exception, "Invalid Path: #{path}"
                end

                if !File.directory?(path)
                    raise Exception, "Invalid Path: #{path}"
                end

                # not_found = []
                # Iterate over the folders in the path
                # Dir.glob("#{path}/*.tif").each do |folder|
                #     # Check if the folder contains the formatted flight date
                #     if File.directory?(folder) && folder.include?(self.flight_date.strftime("%Y%m%d"))
                        # Iterate over the tifs inside the folder
                        Dir.glob("#{path}/*.tif").each do |file|
                            p File.basename(file, ".tif")

                            # Check if the image exists scoped by the VM, flight date, no provisional upload date, and strip_frame
                            # => Also the flight date time must be set
                            fp = self.footprints.has_flight_date_time.find_by(
                                flight_date: self.flight_date,
                                provisional_upload_date: nil,
                                strip_frame: File.basename(file, ".tif")
                            )

                            # p file
                            # p file.split(Rails.application.secrets.naip_exe_folder)

                            if fp
                                # Update the footprints upload date
                                fp.update(
                                    provisional_upload_date: Time.now,
                                )

                                # Update the imagery paths
                                fp.imagery_paths.create(
                                    project: self.project,
                                    user: user,
                                    path: "P:\\#{Rails.application.secrets.naip_exe_required}#{file.split(Rails.application.secrets.naip_exe_folder)[1].gsub(/\//, '\\')}"
                                )

                                count += 1
                            end

                        end
                #     end
                # end

                # if not_found.count == 0 && !self.completed
                if self.footprints.uploaded.count === self.count
                    self.update(provisional_date: Time.now)

                    if !self.imagery_paths.where(project: self.project, path: input_directory).nil?
                        self.imagery_paths.create(
                            project: self.project,
                            path: input_directory,
                            user: user,
                        )
                    end
                end

                # generate the vector metadata
                response[:export] = self.export_footprints user

                # Stt the response
                response[:pass] = true
                response[:message] = "Successfullly updated Vector Metadatum and Exported Shapefile"

            rescue Exception => exception
                Rails.logger.error "Frame Center Import Prep Error: #{exception.message}"
                response[:pass] = false
                response[:message] = [exception.message]

                raise ActiveRecord::Rollback
            end
        end

        response
    end

    def self.production_export project, state_id, user

        # create an Error array to hold any messages
        output = {
            pass: false,
            errors: [],
            count: 0,
            file: nil
        }

        state = State.find_by(id: state_id)
        raise Exception, "Invalid State: #{state}" if state.nil?
        
        # Get the folder name by converting the current time to seconds
        folder = "VM_#{project}_#{state.abv}_#{Time.now.to_i}"

        path = "#{Rails.root}/assets/vector_metadatum_export/#{folder}"

        # Create a folder if it doesn't exist
        FileUtils.mkdir_p("#{path}") unless File.directory?(path)
        FileUtils.mkdir_p("#{path}/json")
        FileUtils.mkdir_p("#{path}/shapefile")
        FileUtils.mkdir_p("#{path}/zipped")

        # Set the formated date to a string to be reused
        time_string = Time.now.strftime("%y%m%d")

        factory = RGeo::GeoJSON::EntityFactory.instance

        file_name = "#{state.abv}_PRODUCTION_ALL"

        features = Array.new

        associations = []

        if project == "NAIP"

            p Doqq.where(state: state).count
            Doqq.where(state: state).each do |record|

                associations << record

                features << factory.feature(record.geom, record.id, {
                    LABEL: record.median_flight_date_time.strftime("%m/%d/%Y").to_s,
                    ACQ_DATE: record.median_flight_date_time.strftime("%m/%d/%Y").to_s,
                    ACQ_TIME: record.median_flight_date_time.strftime("%H:%M").to_s
                })
            end

        elsif project == "SL"

            Tile.where(state: state).each do |record|

                associations << record

                features << factory.feature(record.geom, record.id, {
                    LABEL: record.flight_date.strftime("%m/%d/%Y").to_s,
                    ACQ_DATE: record.flight_date.strftime("%m/%d/%Y").to_s,
                    ACQ_TIME: record.median_flight_date_time.strftime("%H:%M").to_s
                })
            end
        end

        # Creates a text file and saves it to the report directory
        File.open("#{path}/json/#{file_name}.json", "w+") do |f|
            f.puts(RGeo::GeoJSON.encode(factory.feature_collection(features)).to_json)
        end

        # Convert GeoJSON to Shapefile with ogr2ogr
        `ogr2ogr -f "ESRI Shapefile" -fieldTypeToString Date,Time #{path}/shapefile/#{file_name}.shp "#{path}/json/#{file_name}.json"`

        # Zip the files
        Zip::File.open("#{path}/zipped/#{file_name}.zip", Zip::File::CREATE) do |zipfile|
            [".shp", ".shx", ".dbf", ".prj"].each do |ext|
                zipfile.add("#{file_name}#{ext}", File.join("#{path}/shapefile/", "#{file_name}#{ext}"))
            end
        end

        p "#{path}/zipped/#{file_name}.zip"

        # output[:file] = "#{path}/zipped/#{file_name}.zip"
        # output[:file_name] = "#{file_name}.zip"

        # Check for errors
        if output[:errors].count == 0
            output[:pass] = true

            # self.update(shapefile_path: output[:file])

            # Create a new History record
            history = History.new
            history.url = "#{path}/zipped/#{file_name}.zip"
            history.message = "Generated Shapefile for #{project} Production Vector Metadatum Export in #{state.name}"
            history.action_type = "Generated Production Vector Metadatum"
            history.creator = user
            history.save
            
            history.doqqs = associations if project == "NAIP"
            history.tiles = associations if project == "SL"

            output[:history_id] = history.id

        else
            FileUtils.rm_rf(path)
        end

        output

    end

    def export_footprints user

        # create an Error array to hold any messages
        output = {
            pass: false,
            errors: [],
            count: 0,
            file: nil
        }

        if self.footprints.uploaded.has_flight_date_time.count == 0
            return {
                pass: false,
                count: 0, 
                errors: "No Uploaded Footprints Found",
                file: nil
            }
        end

        # Get the folder name by converting the current time to seconds
        folder = "VM_#{self.id}_#{Time.now.to_i}"

        path = "#{Rails.root}/assets/vector_metadatum_export/#{folder}"

        # Create a folder if it doesn't exist
        FileUtils.mkdir_p("#{path}") unless File.directory?(path)
        FileUtils.mkdir_p("#{path}/json")
        FileUtils.mkdir_p("#{path}/shapefile")
        FileUtils.mkdir_p("#{path}/zipped")

        # Create upload instance to track the easements created
        upload = Upload.create(
            folder_path: "#{path}/",
            upload_type: "VectorMetadatum",
            uploader: user
        )

        # Set the formated date to a string to be reused
        time_string = Time.now.strftime("%y%m%d")

        factory = RGeo::GeoJSON::EntityFactory.instance

        file_name = "#{state.abv}_PROVISIONAL_ACQDATE_#{self.flight_date.strftime("%Y%m%d")}"

        features = Array.new

        self.footprints.uploaded.has_flight_date_time.each do |record|
            features << factory.feature(record.geom, record.id, {
                LABEL: record.flight_date.strftime("%m/%d/%Y").to_s,
                ACQ_DATE: record.flight_date.strftime("%m/%d/%Y").to_s,
                ACQ_TIME: record.flight_date_time.strftime("%H:%M").to_s
            })
        end

        # Creates a text file and saves it to the report directory
        File.open("#{path}/json/#{file_name}.json", "w+") do |f|
            f.puts(RGeo::GeoJSON.encode(factory.feature_collection(features)).to_json)
        end

        # Convert GeoJSON to Shapefile with ogr2ogr
        `ogr2ogr -f "ESRI Shapefile" -fieldTypeToString Date,Time #{path}/shapefile/#{file_name}.shp "#{path}/json/#{file_name}.json"`

        # Zip the files
        Zip::File.open("#{path}/zipped/#{file_name}.zip", Zip::File::CREATE) do |zipfile|
            [".shp", ".shx", ".dbf", ".prj"].each do |ext|
                zipfile.add("#{file_name}#{ext}", File.join("#{path}/shapefile/", "#{file_name}#{ext}"))
            end
        end

        p "#{path}/zipped/#{file_name}.zip"

        output[:file] = "#{path}/zipped/#{file_name}.zip"
        output[:file_name] = "#{file_name}.zip"

        # Check for errors
        if output[:errors].count == 0
            output[:pass] = true

            self.update(shapefile_path: output[:file])

            # Create a new History record
            history = History.new
            history.message = "Generated Shapefile for Vector Metadatum Export"
            history.action_type = "Generated Vector Metadatum"
            history.creator = user
            history.save

            # add records to polymorphic association
            history.uploads << upload
            history.footprints = self.footprints.uploaded.has_flight_date_time

        else
            FileUtils.rm_rf(path)
            upload.destroy
        end

        # Return output to controller
        output

    end

    def self.build

        vm_ids = []

        Upload.where(upload_type: "Footprint").each do |upload|

            p upload.id

            next if upload.footprints.count == 0

            # Iterate the Footprints of the upload
            upload.footprints.each do |fp|

                # p fp.id

                # Calculate the business days
                provisional_due_date = fp.flight_date + 5.days

                if provisional_due_date.saturday? 
                    provisional_due_date = provisional_due_date.next_occurring(:monday)
                elsif provisional_due_date.sunday? 
                    provisional_due_date = provisional_due_date.next_occurring(:tuesday)
                end

                # Find or create the VM
                vm = VectorMetadatum.find_or_create_by(
                    project: fp.project, 
                    service_name: "#{fp.state.abv}_PROVISIONAL_4B_#{fp.flight_date.strftime("%Y%m%d")}",
                    state_name: fp.state.name,
                    flight_date: fp.flight_date, 
                    provisional_due_date: provisional_due_date,
                    state_id: fp.state_id
                )

                # Associate the Footprints if they 
                if fp.tiles.count > 0
                    vm.footprints << fp if fp.vector_metadatum_id.nil?
                # else
                #     p "No Tiles Found"
                end

                # Only add ids that are not in the array
                vm_ids |= [vm.id]

            end

        end

        # p vm_ids

        VectorMetadatum.where(id: vm_ids).each do |vm|
            vm.update(count: vm.footprints.count)
        end

    end

    def self.build_production_fix
        # Create the production and provisional vector metadatum
        vm = VectorMetadatum.create(
            project: "NAIP",
            state_name: "New Jersey",
            service_name: "NJ_PRODUCTION_4B_ALL",
            flight_date: "2022-10-28",
            production_date: "2022-10-28",
            state_id: 11
        )

        vm.doqqs << Doqq.all



        # vm = VectorMetadatum.create(
        #     project: "SL",
        #     state_name: "Rhode Island",
        #     service_name: "NJ_PRODUCTION_4B_ALL",
        #     flight_date: "2022-10-28",
        #     production_date: "2022-10-28",
        #     state_id: 11
        # )

    end

    def self.eaws_provisional_check

        return false if VectorMetadatum.includes(:footprints, :doqqs).provisional_active.naip.count == 0

        output = '<html>'\
                    '<table width="100%" style="border: 1px solid black;">'\
                    '<tr>'\
                        '<td align="center" style="border: 1px solid black;">State</td>'\
                        '<td align="center" style="border: 1px solid black;">Flight Date</td>'\
                        '<td align="center" style="border: 1px solid black;">Provisional Count</td>'\
                        '<td align="center" style="border: 1px solid black;">Provisional Uploaded Date</td>'\
                        '<td align="center" style="border: 1px solid black;">Provisional Due Date</td>'\
                        '<td align="center" style="border: 1px solid black;">Production Count</td>'\
                        '<td align="center" style="border: 1px solid black;">Production Uploaded Date</td>'\
                    '</tr>'

        VectorMetadatum.includes(:footprints, :doqqs).provisional_active.naip.each do |vm|

            output += "<tr>"\
                "<td align='center' style='border: 1px solid black;'>#{vm.state_name}</td>"\
                "<td align='center' style='border: 1px solid black;'>#{vm.flight_date.strftime("%m/%d/%Y")}</td>"\
                "<td align='center' style='border: 1px solid black;'>#{vm.footprints.count}</td>"\
                "<td align='center' style='border: 1px solid black;'>#{vm.provisional_date ? vm.provisional_date.strftime("%m/%d/%Y") : "NA"}</td>"\
                "<td align='center' style='border: 1px solid black;'>#{vm.provisional_due_date ? vm.provisional_due_date.strftime("%m/%d/%Y") : "NA"}</td>"\
                "<td align='center' style='border: 1px solid black;'>#{vm.doqqs.count}</td>"\
                "<td align='center' style='border: 1px solid black;'>#{vm.production_date ? vm.production_date.strftime("%m/%d/%Y") : "NA"}</td>"\
            "</tr>"

        end

        output += '</table></html>'

        # Log and send email
        Mailbox.ship({
            users: MailGroup.find_by(name: "EAWS").users | [user],
            subject: "Active Provisional EAWS Report",
            message: output,
            route: Rails.application.routes.url_helpers.imagery_upload_status_url(host: Rails.application.secrets.host)
        })

        # (User.admins + User.managers).each do |user|
        #     PostmasterMailer.notify(user, output.html_safe, "USDA #{Rails.application.secrets.project_year}: Active Provisional EAWS Report", Rails.application.routes.url_helpers.imagery_upload_status_url(host: Rails.application.secrets.host)).deliver
        # end

    end

end
