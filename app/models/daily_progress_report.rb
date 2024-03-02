class DailyProgressReport

    # def self.rebuild
    #     Tile.all.order(:flight_date).pluck(:flight_date).uniq.each do |fd|
    #         DailyProgressReport.generate_new fd, User.admins.first
    #     end
    # end

    def self.generate flight_date, user

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Create a new History record
                history = History.new
                history.action_type = "Daily Progress Report"
                history.creator = user
                
                obj = {
                    sl: {
                        header: flight_date.strftime("%d-%^b-%g"),
                        flight_date: flight_date.strftime("%m/%d/%Y"),
                        accepted: [],
                        rejected: []
                    }
                }

                # Build the file name by recursively checking if the file exists
                file_name = DailyProgressReport.get_report_version flight_date, nil

                # find the tiles that were recently associated by the easements with multiple coverages 
                associated_tiles_not_reported = Tile.sl.flown.where(associate_date: flight_date.strftime("%F")).order(:poly_id)

                # Get the Tiles that match the flight date, even if they have been reported
                # => Also check the rejected tiles 
                tiles_not_reported = Tile.sl.flown.where(flight_date: flight_date.strftime("%F")).order(:poly_id)

                # # Get the rejected Tiles that have already been reported to the USDA but 
                # rejected_tiles = RejectedTile.sl.flown.reported.where(rejected_date: flight_date.strftime("%F")).order(:poly_id)

                # # Creates a text file and saves it to the report directory
                File.open("#{Rails.application.secrets.report_folder}#{file_name}", "w+") do |f|

                    # Write out the header lines
                    # f.puts("To: #{Rails.application.secrets.daily_progress_report_to.join(", ")}")
                    # f.puts("CC: #{Rails.application.secrets.daily_progress_report_cc.join(", ")}")
                    # f.puts("")
                    f.puts("Subject Line:")
                    f.puts("SL #{flight_date.strftime("%d-%^b-%g")}")
                    f.puts("")
                    f.puts("Body:")
                    f.puts("Date Acquired: #{flight_date.strftime("%d-%^b-%g")}")

                    if (associated_tiles_not_reported.count + tiles_not_reported.count) > 0
                        f.puts("")
                        f.puts("Easements Acquired:")
                        f.puts("")
                    end

                    associated_tiles_not_reported.each do |tile|
                        # Update the tile's report date if it's not set
                        tile.update(report_date: Time.now) if tile.report_date.nil?

                        # Pass to object aray for rendering
                        obj[:sl][:accepted] << {date: tile.flight_date.strftime("%d-%^b-%g"), poly_id: tile.poly_id}

                        # Write to file
                        f.puts(tile.poly_id)
                    end

                    # update the tiles to today's date
                    tiles_not_reported.each do |tile|
                        # Update the tile's report date if it's not set
                        tile.update(report_date: Time.now) if tile.report_date.nil?

                        # Pass to object aray for rendering
                        obj[:sl][:accepted] << {date: flight_date.strftime("%d-%^b-%g"), poly_id: tile.poly_id}

                        # Write to file
                        # f.puts("#{flight_date.strftime("%d-%^b-%g")}\t#{tile.poly_id}\tA")
                        f.puts(tile.poly_id)
                    end

                    # if rejected_tiles.count > 0
                    #     f.puts("")
                    #     f.puts("Easements Rejected:")
                    #     f.puts("")
                    # end

                    # rejected_tiles.each do |rejected_tile|
                    #     # Update the recjected tile's rejection report date if it's not set
                    #     rejected_tile.update(rejection_report_date: Time.now) if rejected_tile.rejection_report_date.nil?
                        
                    #     # Pass to object aray for rendering
                    #     obj[:sl][:rejected] << {date: rejected_tile.flight_date.strftime("%d-%^b-%g"), poly_id: rejected_tile.poly_id}

                    #     # Write to file
                    #     f.puts(rejected_tile.poly_id)
                    # end

                end

                # Add associations to history obj
                history.tiles << tiles_not_reported
                # history.rejected_tiles << rejected_tiles_not_reported
                # history.rejected_tiles << rejected_tiles

                # Get the folder name by converting the current time to seconds
                folder = Time.now.to_i

                path = "#{Rails.root}/assets/daily_progress_reports/#{folder}"

                # Create the Daily Progress Report if it doesn't exist
                FileUtils.mkdir_p(path) unless File.directory?(path)

                # Copy the text file to local assets
                FileUtils.cp("#{Rails.application.secrets.report_folder}#{file_name}", "#{path}/#{file_name}")

                # update message
                history.url = "#{path}/#{file_name}"
                history.message = "Executed Daily Progress Report for #{flight_date.strftime("%m/%d/%Y")}"
                history.save

                html = "<p>A Daily Progress report was generated by #{user.first_name} #{user.last_name} for #{flight_date.strftime("%m/%d/%Y")} with #{obj[:sl][:accepted].size} Tiles being marked as Approved</p>"
                # html += "<p>This does not indicate the email was sent to the USDA and it is #{user.first_name} #{user.last_name} responsibility to send.</p>"
                html += "<p>This report needs to be sent by the person above who generated the report as it contains critical one-time acceptance and rejection information to the USDA. </p>"
                html += "<hr />"

                html += "<p>Date Acquired: #{flight_date.strftime("%d-%^b-%g")}</p>"

                html += "<p>Easements Acquired:</p>"

                obj[:sl][:accepted].each {|item| html += "<pre style='margin: 0;'>#{item[:poly_id]}</pre>"}
                # obj[:sl][:rejected].each {|item| html += "<pre style='margin: 0;'>#{item[:poly_id]}</pre>"}

                # Log and send email
                Mailbox.ship({
                    users: MailGroup.find_by(name: "Daily Progress Report").users,
                    subject: "Daily Progress Report was generated - #{flight_date.strftime("%m/%d/%Y")}",
                    message: html
                })

                obj

            end
        end

    end

    # def self.generate flight_date, user

    #     # get the tiles that match the flight date and do not have a reported date
    #     # get all rejections that do not have a rejection_reported_date set that are older or equal to the selected date

    #     # Start a Transaction Block
    #     ActiveRecord::Base.transaction do
    #         begin

    #             # Create a new History record
    #             history = History.new
    #             history.action_type = "Daily Progress Report"
    #             history.creator = user
                
    #             obj = {
    #                 sl: {
    #                     header: "SL #{flight_date.strftime("%d-%^b-%g")}",
    #                     flight_date: flight_date.strftime("%m/%d/%Y"),
    #                     accepted: [],
    #                     rejected: []
    #                 }
    #             }

    #             # Build the file name by recursively checking if the file exists
    #             file_name = DailyProgressReport.get_report_version flight_date, nil

    #             # find the tiles that were recently associated by the easements with multiple coverages 
    #             associated_tiles_not_reported = Tile.sl.flown.where(associate_date: flight_date.strftime("%F")).order(:poly_id)

    #             # Get the Tiles that match the flight date, even if they have been reported
    #             # => Also check the rejected tiles 
    #             tiles_not_reported = Tile.sl.flown.where(flight_date: flight_date.strftime("%F")).order(:poly_id)

    #             # Get the rejected Tiles that have already been reported to the USDA but 
    #             rejected_tiles = RejectedTile.sl.flown.reported.where(rejected_date: flight_date.strftime("%F")).order(:poly_id)

    #             # # Creates a text file and saves it to the report directory
    #             File.open("#{Rails.application.secrets.report_folder}#{file_name}", "w+") do |f|

    #                 # Write out the header lines
    #                 f.puts("To: #{Rails.application.secrets.daily_progress_report_to.join(", ")}")
    #                 f.puts("CC: #{Rails.application.secrets.daily_progress_report_cc.join(", ")}")
    #                 f.puts("")
    #                 f.puts("Subject Line:")
    #                 f.puts("SL #{flight_date.strftime("%d-%^b-%g")}")
    #                 f.puts("")
    #                 f.puts("Body:")

    #                 associated_tiles_not_reported.each do |tile|
    #                     # Update the tile's report date if it's not set
    #                     tile.update(report_date: Time.now) if tile.report_date.nil?

    #                     # Pass to object aray for rendering
    #                     obj[:sl][:accepted] << {date: tile.flight_date.strftime("%d-%^b-%g"), poly_id: tile.poly_id}

    #                     # Write to file
    #                     f.puts("#{tile.flight_date.strftime("%d-%^b-%g")}\t#{tile.poly_id}\tA")
    #                 end

    #                 # update the tiles to today's date
    #                 tiles_not_reported.each do |tile|
    #                     # Update the tile's report date if it's not set
    #                     tile.update(report_date: Time.now) if tile.report_date.nil?

    #                     # Pass to object aray for rendering
    #                     obj[:sl][:accepted] << {date: flight_date.strftime("%d-%^b-%g"), poly_id: tile.poly_id}

    #                     # Write to file
    #                     f.puts("#{flight_date.strftime("%d-%^b-%g")}\t#{tile.poly_id}\tA")
    #                 end

    #                 rejected_tiles.each do |rejected_tile|
    #                     # Update the recjected tile's rejection report date if it's not set
    #                     rejected_tile.update(rejection_report_date: Time.now) if rejected_tile.rejection_report_date.nil?
                        
    #                     # Pass to object aray for rendering
    #                     obj[:sl][:rejected] << {date: rejected_tile.flight_date.strftime("%d-%^b-%g"), poly_id: rejected_tile.poly_id}

    #                     # Write to file
    #                     f.puts("#{rejected_tile.flight_date.strftime("%d-%^b-%g")}\t#{rejected_tile.poly_id}\tR")
    #                 end

    #             end

    #             # Add associations to history obj
    #             history.tiles << tiles_not_reported
    #             # history.rejected_tiles << rejected_tiles_not_reported
    #             history.rejected_tiles << rejected_tiles

    #             # Get the folder name by converting the current time to seconds
    #             folder = Time.now.to_i

    #             path = "#{Rails.root}/assets/daily_progress_reports/#{folder}"

    #             # Create the Daily Progress Report if it doesn't exist
    #             FileUtils.mkdir_p(path) unless File.directory?(path)

    #             # Copy the text file to local assets
    #             FileUtils.cp("#{Rails.application.secrets.report_folder}#{file_name}", "#{path}/#{file_name}")

    #             # update message
    #             history.url = "#{path}/#{file_name}"
    #             history.message = "Executed Daily Progress Report for #{flight_date.strftime("%m/%d/%Y")}"
    #             history.save

    #             html = "<p>A Daily Progress report was generated by #{user.first_name} #{user.last_name} for #{flight_date.strftime("%m/%d/%Y")} with #{obj[:sl][:accepted].size} Tiles being marked as Approved and #{obj[:sl][:rejected].size} Rejected.</p>"
    #             # html += "<p>This does not indicate the email was sent to the USDA and it is #{user.first_name} #{user.last_name} responsibility to send.</p>"
    #             html += "<p>This report needs to be sent by the person above who generated the report as it contains critical one-time acceptance and rejection information to the USDA. </p>"
    #             html += "<hr />"

    #             obj[:sl][:accepted].each {|item| html += "<pre style='margin: 0;'>#{item[:date]}&#09;#{item[:poly_id]}&#09;A</pre>"}
    #             obj[:sl][:rejected].each {|item| html += "<pre style='margin: 0;'>#{item[:date]}&#09;#{item[:poly_id]}&#09;R</pre>"}

    #             # Log and send email
    #             Mailbox.ship({
    #                 users: MailGroup.find_by(name: "Daily Progress Report").users,
    #                 subject: "Daily Progress Report was generated - #{flight_date.strftime("%m/%d/%Y")}",
    #                 message: html
    #             })

    #             obj

    #         end
    #     end

    # end

    def self.daily_check

        p "DAILY CHECK - #{Time.now}"

        # Checks if there were any flight dates older than yesterday that have not been reported
        # Also checks if there are any rejections that 
        # does not run on the weekends, only weekdays

        yesterday = Date.yesterday.strftime("%F")
        # yesterday = "2023-04-11"

        # tiles_not_reported = Tile.flown.not_reported.where("project = 'SL' AND flight_date <= '#{yesterday}'").order(:flight_date)
        tiles_not_reported = Tile.sl.flown.not_reported.where("flight_date <= '#{yesterday}'")

        # rejected_tiles_not_reported = RejectedTile.flown.rejection_not_reported.where("project = 'SL' AND flight_date <= '#{yesterday}'").order(:rejected_date)
        # rejected_tiles_not_reported = RejectedTile.sl.flown.not_reported.where("rejected_date <= '#{yesterday}'")

        # if tiles_not_reported.size > 0 || rejected_tiles_not_reported.size > 0
        if tiles_not_reported.size > 0
            # Send Notification to process yesterday's Daily Progress Reports

            html = "There are Tiles that have not been reported as Accepted or Rejected in the system. We are required to send the Daily Progress Reports for a given Flight Date or Rejection by the following business day."
            html += "<hr/>"

            if tiles_not_reported.size > 0
                html += "<h4>Accepted but not Reported</h4>"
                html += "<ul>"
                tiles_not_reported.pluck(:flight_date).uniq.each do |flight_date|
                    count = Tile.sl.flown.not_reported.select(:id).where(flight_date: flight_date).count
                    html += "<li>Flight Date: #{flight_date.strftime("%m/%d/%Y")} - #{count} #{"Tile".pluralize(count)}</li>"
                end
                html += "</ul>"
            end

            # if rejected_tiles_not_reported.size > 0
            #     html += "<h4>Rejected Tiles not Reported</h4>"
            #     html += "<ul>"
            #     rejected_tiles_not_reported.pluck(:rejected_date).uniq.each do |rejected_date|
            #         count = RejectedTile.sl.flown.not_reported.select(:id).where(rejected_date: rejected_date).count
            #         html += "<li>Rejection Date: #{rejected_date.strftime("%m/%d/%Y")} - #{count} #{"Tile".pluralize(count)}</li>"
            #     end
            #     html += "</ul>"
            # end

            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Daily Progress Report").users,
                subject: "Daily Progress Reports need to be sent - #{Date.today.strftime("%m/%d/%Y")}",
                message: html
            })

        end

    end

    # Check if the file exists and if so then add the version number to it
    def self.get_report_version flight_date, version

        if version.nil?
            file_name = "#{flight_date.strftime("%y%m%d")}_DailyProgressReport.txt"
            version = 0
        else
            file_name = "#{flight_date.strftime("%y%m%d")}_DailyProgressReport_#{version}.txt"
        end

        if File.exists? "#{Rails.application.secrets.report_folder}#{file_name}"
            version += 1
            return DailyProgressReport.get_report_version flight_date, version
        else
            return file_name
        end 

    end

end
