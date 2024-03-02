class UptimeLog < ApplicationRecord

    # Associations
    belongs_to :upload
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs

    # Validations
    validates :logged_at, uniqueness: { scope: [:location, :response_time] }

    def self.prepare_import params, user

        response = {
            pass: false,
            message: nil
        }

        path = nil
        file_path = nil

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                file = params[:file]
                project = params[:project]

                p "========="
                p file

                if File.extname(file.original_filename) != ".csv"
                    raise Exception, "Supplied File is not a CSV file"
                end

                # Get the folder name by converting the current time to seconds
                folder = Time.now.to_i

                path = "#{Rails.root}/assets/uptime_logs/#{folder}"

                # Create a folder if it doesn't exist
                FileUtils.mkdir_p(path) unless File.directory?(path)

                file_path = "#{path}/#{file.original_filename}"

                # Move the file to the server
                FileUtils.mv file.tempfile, file_path

                response[:pass] = true
                response[:message] = "Successfully uploaded log file and processing will begin shortly"

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
            UptimeLog.delay.import file_path, user
        end

        response

    end
    
    def self.import file_path="/home/booshwa/Desktop/nri/nri2022/assets/uptime_logs/1653322092/Log Report_2022-05-23_07-53.csv", user=User.first

        count = 0

        job = Job.create(
            started_at: Time.now,
            active: true,
            message: "Processing Request...",
            process_type: "Uptime Log Import",
            creator: user
        )

        # Create upload instance to track the easements created
        upload = Upload.create(
            folder_path: "#{file_path}",
            upload_type: "UptimeLog",
            uploader: user
        )

        # Stores variables for the job process
        process_success = false
        error_message = "Something went wrong. Contact Programming"

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # check if the path exists
                if !File.exist? file_path
                    raise Exception, "File not found: #{file_path}"
                end

                # Open the Log file
                log = CSV.read(file_path, headers:true)

                # Iterate
                log.each do |row|

                    # Create a new record
                    record = UptimeLog.new(
                        location: row['Location'] == "-" ? nil : row['Location'],
                        logged_at: row['Collection Time'],
                        status: row['HTTP Status Code'],
                        dns_response_time: row['DNS Response Time (ms)'],
                        ssl_handshake_time: row['SSL Handshake Time (ms)'],
                        connection_time: row['Connection Time (ms)'],
                        response_time: row['Response Time (ms)'],
                        reason: row['Reason'] == "-" ? nil : row['Reason'],
                        upload: upload
                    )

                    # check if it saves
                    if record.save
                        count += 1
                    else
                        # Rails Exception if errors
                        raise Exception, "Error saving Uptime Log Record (#{row['Collection Time']}): #{record.errors.full_messages.to_sentence}"
                    end

                end

                if count > 0
                    job.update(
                        finished_at: Time.now,
                        success: true,
                        active: false,
                        upload: upload,
                        message: "Uploaded #{count} records!"
                    )

                    # Create a new History record
                    history = History.new
                    history.action_type = "Upload Uptime Logs"
                    history.creator = user
                    history.message = "Uploaded #{count} Records"
                    history.save

                    history.uploads << upload
                    history.uploads << upload

                    # Log and send email
                    Mailbox.ship({
                        users: MailGroup.find_by(name: "EAWS").users | [user],
                        subject: "Uptime Log Import Succeeded",
                        message: "Uptime Log Import was successfully imported"
                    })

                    # Update the process
                    process_success = true
                    
                end

            rescue Exception => exception
                p exception.message
                Rails.logger.error "Uptime Log Import Error: #{exception.message}"
                error_message = exception.message

                # Delete the Upload and History
                upload.destroy if upload
                history.destroy if history

                # Delete the files
                # FileUtils.rm_rf("#{path}/") if path

                # Update the process
                process_success = false

                ActiveRecord::Rollback
            end
        end

        # Run if the process failed
        if !process_success

            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "EAWS").users | [user],
                subject: "Uptime Log Import Failed",
                message: "Uptime Log Import Failed, error encountered is listed below: <br/><br/>#{error_message}"
            })

            # Send email to notified it failed
            # PostmasterMailer.notify(user, "Uptime Log Import Failed, error encountered is listed below: <br/><br/>#{error_message}".html_safe, "USDA #{Rails.application.secrets.project_year}: Uptime Log Import Failed - #{Time.now.strftime("%m/%d/%Y")}").deliver

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

        p job

    end

end
