class WebLogUpload < ApplicationRecord

    # Associations
    has_many :web_logs
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs

    def self.import input_directory, user=User.first
        # P:\Vol_2\226578_01_USDA_NJ_NAIP\04_EAWS\EsriLogFiles\20221010_20221016

        job = Job.create(
            started_at: Time.now,
            active: true,
            message: "Processing Import...",
            process_type: "Web Log Import",
            creator: user,
        )

        # Stores variables for the job process
        process_success = false
        error_message = "Something went wrong. Contact Programming"

        # Testing
        # WebLogUpload.destroy_all
        # WebLog.destroy_all
        # WebLogSummary.destroy_all
        f = File.open("/media/sf_shared/2026/Audit/esri_log_import_not_imported.txt", "w+") if Rails.env.development?

        total = 0
        count = 0

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Convert the input 
                path = Task.build input_directory

                if !path
                    raise Exception, "Invalid Input Directory: #{input_directory}"
                end

                # p input_directory 
                # p Rails.application.secrets.esri_log_required

                raise Exception, "Log Files must be stored within #{Rails.application.secrets.esri_log_required}" if !input_directory.include?(Rails.application.secrets.esri_log_required)

                path_array = path.split("/").delete_if(&:blank?)

                if path_array.size <= 4
                    raise Exception, "Select a nested folder stored within #{Rails.application.secrets.esri_log_required}, not the root folder"
                end

                # Create the upoad 
                upload = WebLogUpload.create(
                    path: path
                )

                # Keep track of the total records
                total_logs = 0
                summary_ids = []

                # get the service names
                # service_names = VectorMetadatum.where(state_id: [5, 11]).pluck(:service_name) + ["NJ_PROVISIONAL_4B_ALL", "NJ_PRODUCTION_4B_ALL", "RI_PROVISIONAL_4B_ALL", "RI_PRODUCTION_4B_ALL"]

                Dir.glob(File.join("#{path}/**","*.json")).each do |path|
                # files.each do |path|
                    # p path

                    json_file = File.open(path)
                    file_data = json_file.read

                    # Check if the file contents includes "exportImage" 
                    # if !file_data.include? "exportImage"
                    #     next
                    # end

                    # if !service_names.any? { |service| file_data.include?(service) }
                    #     next
                    # end

                    # p file_data

                    # ESRI log files are not valid json and need cleanup before iteration
                    # => Remove the newlines
                    # => Add commas after each record
                    # => Remove the last comma on the final record
                    # => return an an array
                    file_data = "[#{file_data.strip.gsub("}}", "}},").chop}]"

                    # parse the json and return false if not valid
                    records = self.parse file_data

                    # p records

                    # If the records are instad false then throw error
                    if !records
                        raise Exception, "Invalid JSON File Detected: #{path}"
                    end

                    # If all good then start iterating
                    records.each do |record|

                        total += 1

                        # p "#{record["properties"]["requestUri"].include?("exportImage") || record["properties"]["httpMethod"] == "POST"} : #{record["properties"]["httpMethod"]} #{record["properties"]["requestUri"]}"

                        # p "#{record["timeStamp"]} : #{record["properties"]["httpMethod"]} #{record["properties"]["requestUri"]}" if record["properties"]["requestUri"].include? "\/arcgis\/services\/naip\/NJ_PROVISIONAL_4B_ALL\/ImageServer"

                        # if !service_names.any? { |service| record["properties"]["requestUri"].include?(service) }
                        #     next
                        # end

                        next if record["properties"]["userAgent"] == "Site24x7" || record["properties"]["serverStatus"] != "200"

                        # if (record["properties"]["requestUri"].include?("exportImage") || record["properties"]["httpMethod"] == "POST") && record["properties"]["requestUri"].size > 5  && record["properties"]["serverStatus"] == "200" && ["/naip/", "/nri/", "/sl/"].any? { |service| record["properties"]["requestUri"].include?(service) }
                        if record["properties"]["requestUri"].downcase.include?("imageserver") && record["properties"]["requestUri"].size > 5  && record["properties"]["serverStatus"] == "200" && ["/naip/", "/nri/", "/sl/", "_provisional_", "_production_"].any? { |service| record["properties"]["requestUri"].downcase.include?(service) }

                            # Skip if it is a metadata, info, or login redirect request
                            next if ["metadata", "f=json", "login"].any? { |service| record["properties"]["requestUri"].downcase.include?(service) }

                            # p record["properties"]["requestUri"]
                            count += 1

                            # Extract the Project and Service Name

                            # Remove the parameters
                            url = record["properties"]["requestUri"].upcase.split("?")[0]

                            # Split up the remaining array
                            url_split = url.split("/")

                            # Find the project folder in the array

                            # Get the project name based on the avialable projects
                            project = url_split.select{|x| ["NAIP", "NRI", "SL"].include?(x)}
                            raise Exception, "Could not determine project for \"#{record["properties"]["requestUri"]}\" in #{path}" if project.size != 1
                            # next if project.size != 1
                            # if project.size != 1
                            #     p "#{record["timeStamp"]} #{record["properties"]["requestUri"]}" if record["properties"]["requestUri"].include?("NJ_PROVISIONAL_4B_ALL")
                            #     next
                            # end
                            project = project[0]

                            # find the index of the project in the url
                            project_index = url_split.index(project)

                            # Add one ot the project index and 
                            service_name = url_split[project_index+1]

                            # p service_name

                            # # get the service name comparing to existing service names
                            # service_name = url_split.select{|x| service_names.include?(x)}
                            # # raise Exception, "Could not extract Service Name for \"#{record["properties"]["requestUri"]}\" in #{path}" if service_name.size != 1
                            # if service_name.size != 1
                            #     p "#{record["timeStamp"]} #{record["properties"]["requestUri"]}" if record["properties"]["requestUri"].include?("NJ_PROVISIONAL_4B_ALL")
                            #     next
                            # end
                            # service_name = service_name[0].upcase

                            # # Get the project name based on the avialable projects
                            # project = url_split.select{|x| ["naip", "nri", "sl"].include?(x)}
                            # # raise Exception, "Could not determine project for \"#{record["properties"]["requestUri"]}\" in #{path}" if project.size != 1
                            # # next if project.size != 1
                            # if project.size != 1
                            #     p "#{record["timeStamp"]} #{record["properties"]["requestUri"]}" if record["properties"]["requestUri"].include?("NJ_PROVISIONAL_4B_ALL")
                            #     next
                            # end
                            # project = project[0].upcase

                            # p "YES : #{record["properties"]["requestUri"]}"
                            
                            # # Get the project
                            # if ["naip", "nri", "sl"].include? url_split[4]
                            #     project = url_split[4].upcase
                            #     # p "Project: #{project}"
                            # end

                            # Get the current time
                            logged_at = Time.parse(record["time"])

                            # Get the Vector Metadata
                            vm = VectorMetadatum.find_by(project: project.upcase, service_name: service_name)

                            # Find or create the log summary
                            summary = WebLogSummary.find_or_create_by(
                                project: project,
                                log_date: logged_at,
                                service: service_name,
                                ip_address: record["properties"]["clientIP"],
                                domain: record["properties"]["originalHost"],
                                vector_metadatum: vm
                            )

                            # Add the summary id to the array
                            summary_ids |= [summary.id]

                            # Check if the log file already exists, only do it if the match is outside the current web log summary
                            existing = WebLog.find_by(project: project, service: service_name, logged_at: logged_at)
                            if existing && existing.web_log_upload_id != upload.id
                                # p "#{record["timeStamp"]} #{record["properties"]["requestUri"]}"
                                next
                            end

                            # Create the log
                            log = upload.web_logs.create!(
                                project: project,
                                service: service_name,
                                logged_at: logged_at,
                                ip_address: record["properties"]["clientIP"],
                                domain: record["properties"]["originalHost"],
                                bytes: record["properties"]["sentBytes"],
                                total_time: record["properties"]["timeTaken"],
                                status: record["properties"]["httpStatus"],
                                source: record["properties"]["requestUri"],
                                path: path,
                                web_log_summary: summary,
                                vector_metadatum: vm
                            )

                            total_logs += 1
                        else
                            f.puts "#{record} \n" if record["properties"]["requestUri"] != "" && Rails.env.development?
                            next
                        end
                    end
                end

                # Update the counts on the WebLogSummary
                WebLogSummary.includes(:web_logs).where(id: summary_ids).each {|wls| wls.update(count: wls.web_logs.count)}
                
                # Create a new History record
                history = History.new
                history.action_type = "Import ESRI Log Files"
                history.creator = user
                history.message = "Uploaded #{total_logs} Logs"
                history.save

                # Add the logs to the history
                history.web_log_uploads << upload

                # Get the start and end dates of the log files for the import
                upload.update(
                    start_date: upload.web_logs.count > 0 ? upload.web_logs.select(:logged_at).order(:logged_at).first.logged_at : nil,
                    end_date: upload.web_logs.count > 0 ? upload.web_logs.select(:logged_at).order(:logged_at).last.logged_at : nil,
                    count: total_logs
                )

                job.update(
                    finished_at: Time.now,
                    success: true,
                    active: false,
                    # upload: upload,
                    message: "Uploaded #{total_logs} Logs from #{input_directory}"
                )

                # Update the process 
                process_success = true

                # Send email to notified it failed
                # PostmasterMailer.notify(user, "ESRI Log Import Completed, uploaded #{total_logs} Logs from #{input_directory}", "USDA #{Rails.application.secrets.project_year}: ESRI Log Import Completed - #{Time.now.strftime("%m/%d/%Y")}").deliver

            rescue Exception => exception
                Rails.logger.error "Web Log Import Error: #{exception.message}"

                error_message = exception.message

                # Update the process 
                process_success = false

                raise ActiveRecord::Rollback
            end
        end

        f.close if Rails.env.development?

        # Run if the process failed
        # if !process_success

        #     # Send email to notified it failed
        #     PostmasterMailer.notify(user, "ESRI Log Import Failed while importing from #{input_directory}.<br/><br/>#{error_message}".html_safe, "USDA #{Rails.application.secrets.project_year}: ESRI Log Import Failed - #{Time.now.strftime("%m/%d/%Y")}").deliver

        #     # Update the Job
        #     job.update(
        #         finished_at: Time.now,
        #         active: false,
        #         success: false,
        #         message: "Import Failed",
        #         upload: nil,
        #         error_message:  error_message
        #     )

        # end
    
        p "#{count}/#{total}"
        p "done: #{process_success}"

    end

    private

    def self.parse(json)
        data = JSON.parse(json)
        return data
      rescue JSON::ParserError => e
        p "_____________"
        p e.message
        p "_____________"
        return false
    end 

end
