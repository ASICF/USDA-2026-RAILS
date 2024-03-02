class WebLogSummary < ApplicationRecord

    # Associations
    belongs_to :vector_metadatum, optional: true
    has_many :web_logs

    def self.query project, date_from, date_to
        # WebLog.query "NAIP", "2022-04-30", "2022-06-06"

        output = {
            state: true,
            result: {},
            message: "Something went wrong. Contact Programming."
        }

        begin

            # Convert to datetime
            date_from = Time.parse(date_from).to_datetime
            date_to = Time.parse(date_to).to_datetime

            # Query the Web Logs
            log_summaries = WebLogSummary.where(project: project, log_date: date_from..date_to)


            p log_summaries

            # if log_summaries.size == 0
            #     return {
            #         state: false,
            #         message: "No logs found for date range"
            #     }
            # end

            # Iterate and build the usage report
            # REQUIREMNTS!
            # 1. Number of unique uses by week
            # 2. Number of image requests
            # 3. Ip/Domain names of the top 20 users

            obj = {
                unique_users: [],
                image_requests: [],
                top_20_users: [],
            }

            # Number of Image Requests
            image_request_obj = {}
            unique_uses_obj = {}
            log_summaries.each do |log|

                
                # Create the record if it doesn't exist
                if unique_uses_obj["#{log.project}_#{log.service}_#{log.ip_address}".to_sym].nil?
                    unique_uses_obj["#{log.project}_#{log.service}_#{log.ip_address}".to_sym] = {
                        project: log.project,
                        service: log.service,
                        ip_address: log.ip_address,
                        domain: log.domain,
                        count: 0
                    }
                end

                # Create the record if it doesn't exist
                if image_request_obj["#{log.project}_#{log.service}".to_sym].nil?
                    image_request_obj["#{log.project}_#{log.service}".to_sym] = {
                        project: log.project,
                        service: log.service,
                        count: 0
                    }
                end

                # Add the count to the record
                unique_uses_obj["#{log.project}_#{log.service}_#{log.ip_address}".to_sym][:count] += log.count
                image_request_obj[:"#{log.project}_#{log.service}"][:count] += log.count
            end

            # Convert to an array
            unique_users_arr = unique_uses_obj.map {|key, record| record}
            arr = image_request_obj.map {|key, record| record}

            # Sort the array
            # => Reverse it to get it in descending order
            unique_users_arr.sort_by! {|record| record[:count] }
            arr.sort_by! {|record| record[:count] }

            # Iterate over the hash
            obj[:unique_users] = unique_users_arr.reverse
            obj[:image_requests] = arr.reverse
            # arr.reverse.each do |record|
            #     obj[:image_requests] = record
            # end

            # Get the top 20 users
            num_20_users = {}
            log_summaries.each do |log|

                # Create the record if it doesn't exist
                if num_20_users[:"#{log.project}_#{log.ip_address}_#{log.domain}"].nil?
                    num_20_users[:"#{log.project}_#{log.ip_address}_#{log.domain}"] = {
                        project: log.project,
                        ip_address: log.ip_address,
                        domain: log.domain,
                        count: 0
                    }
                end

                # Add the count to the record
                num_20_users[:"#{log.project}_#{log.ip_address}_#{log.domain}"][:count] += log.count
            end

            # Convert to an array
            arr = num_20_users.map {|key, record| record}

            # Sort the array
            # => Reverse it to get it in descending order
            arr.sort_by! {|record| record[:count] }

            # Iterate over the hash
            obj[:top_20_users] = arr.reverse
            # arr.reverse.each do |record|
            #     obj[:top_20_users] << record
            # end

            output[:result] = obj
            if log_summaries.count == 0
                output[:state] = false
                output[:message] = "No Log Summaries found"
            else
                output[:message] = "Successfully queried #{log_summaries.size} log Summary Records"
            end

            return output

        rescue StandardError => e
            p e.message
            return {
                state: false,
                message: "Error: #{e.message}"
            }

        end

    end

    def self.export project, date_from, date_to, user

        begin

            # Query to get the results
            query_result = self.query project, date_from, date_to

            p "_______"
            pp query_result

            # Convert to datetime
            date_from = Time.parse(date_from).to_datetime
            date_to = Time.parse(date_to).to_datetime

            # Create the new excel file and intiailizte the workbook
            package = Axlsx::Package.new
            wb = package.workbook

            # Unique Uses
            # => unique based on Service name, ip_addres, :domain
            wb.add_worksheet(name: "Unique Uses") do |sheet|
                sheet.add_row [
                    "Project",
                    "Service",
                    "IpAddress",
                    "Domain",
                    "Count"
                ]
                query_result[:result][:unique_users].each do |record|
                    p record
                    sheet.add_row [
                        record[:project],
                        record[:service],
                        record[:ip_address],
                        record[:domain],
                        record[:count]
                    ]
                end
            end

            # Number of Image Requests
            # => unique based on Service name, ip_addres, :domain
            wb.add_worksheet(name: "Image Requests") do |sheet|
                sheet.add_row [
                    "Project",
                    "Service",
                    "Count"
                ]

                # Iterate over the hash
                query_result[:result][:image_requests].each do |record|
                    sheet.add_row [
                        record[:project],
                        record[:service],
                        record[:count],
                    ]
                end
            end

            # Number of Image Requests
            # => unique based on Service name, ip_addres, :domain
            wb.add_worksheet(name: "Top 20 Users") do |sheet|
                sheet.add_row [
                    "Project",
                    "IpAddress",
                    "Domain",
                    "Count"
                ]

                # Iterate over the hash
                query_result[:result][:top_20_users].each do |record|
                    sheet.add_row [
                        record[:project],
                        record[:ip_address],
                        record[:domain],
                        record[:count],
                    ]
                end
            end

            # Write to output
            path = Rails.root.join('assets', 'eaws_usage_report')
            folder = Time.now.to_i
            Dir.mkdir("#{path}/#{folder}") unless File.directory?("#{path}/#{folder}")
            filename = "ASI #{project} EAWS Usage Statistics Report (#{date_from.strftime("%F")} - #{date_to.strftime("%F")})"
            file_path="#{path}/#{folder}/#{filename}.xlsx"
            package.serialize(file_path)

            history = History.new
            history.action_type = "EAWS Usage Reports"
            history.creator = user
            history.url = file_path
            history.message = "Generated report #{filename}.xlsx"
            history.save

            return {
                state: true,
                # file: file_path,
                filename: filename,
                history_id: history.id
            }

        rescue StandardError => e
            p e.message
            return {
                state: false,
                message: "Error: #{e.message}"
            }

        end

    end

end
