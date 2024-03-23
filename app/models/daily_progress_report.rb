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
                    },
                    nri: {
                        header: flight_date.strftime("%d-%^b-%g"),
                        flight_date: flight_date.strftime("%m/%d/%Y"),
                        accepted: [],
                        rejected: []
                    }
                }

                nri_associated_tiles_not_reported = []
                sl_associated_tiles_not_reported = []

                # find the tiles that were recently associated by the easements with multiple coverages 
                sl_associated_tiles_not_reported |= Tile.sl.flown.where(associate_date: flight_date.strftime("%F")).order(:poly_id)
                nri_associated_tiles_not_reported |= Tile.nri.flown.where(associate_date: flight_date.strftime("%F")).order(:poly_id)

                # Get the Tiles that match the flight date, even if they have been reported
                # => Also check the rejected tiles 
                sl_associated_tiles_not_reported |= Tile.sl.flown.where(flight_date: flight_date.strftime("%F")).order(:poly_id)
                nri_associated_tiles_not_reported |= Tile.nri.flown.where(flight_date: flight_date.strftime("%F")).order(:poly_id)

                # find the tiles that were recently associated by the easements with multiple coverages 
                # nri_associated_tiles_not_reported = Tile.nri.flown.where(associate_date: flight_date.strftime("%F")).order(:poly_id)
                # sl_associated_tiles_not_reported = Tile.sl.flown.where(associate_date: flight_date.strftime("%F")).order(:poly_id)

                # p "-------"
                # p "NRI: #{nri_associated_tiles_not_reported.count}"
                # p "SL: #{sl_associated_tiles_not_reported.count}"

                # Check if the NRI or SL have tiles to be reported
                if nri_associated_tiles_not_reported.count > 0 || sl_associated_tiles_not_reported.count > 0

                    # Build the file name by recursively checking if the file exists
                    file_name = DailyProgressReport.get_report_version flight_date, nil

                    # p file_name

                    file_path = "#{Rails.application.secrets.report_folder}#{file_name}"

                    # Create the output file
                    out_file = File.open(file_path, "w+")

                    # Write out the header lines
                    # f.puts("To: #{Rails.application.secrets.daily_progress_report_to.join(", ")}")
                    # f.puts("CC: #{Rails.application.secrets.daily_progress_report_cc.join(", ")}")
                    # f.puts("")
                    # out_file.puts("Subject Line:")
                    # out_file.puts("#{flight_date.strftime("%d-%^b-%g")}")
                    # out_file.puts("")
                    # out_file.puts("Body:")
                    # out_file.puts("")
                    # out_file.puts("Date Acquired: #{flight_date.strftime("%d-%^b-%g")}")
                    # out_file.close

                    # Check if there are NRI tiles to report
                    if nri_associated_tiles_not_reported.count > 0

                        # Get the Tiles that match the flight date, even if they have been reported
                        # => Also check the rejected tiles 
                        nri_tiles_not_reported = Tile.nri.flown.where(flight_date: flight_date.strftime("%F")).order(:poly_id)

                        # p "nri_associated_tiles_not_reported #{nri_associated_tiles_not_reported.count}"
                        # p "nri_tiles_not_reported #{nri_tiles_not_reported.count}"

                        # Add the header
                        out_file = File.open(file_path, "a")
                        out_file.puts("========= NRI =========")
                        out_file.puts("Subject Line:")
                        out_file.puts("#{flight_date.strftime("%d-%^b-%g")}")
                        out_file.puts("")
                        out_file.puts("Body:")
                        out_file.puts("Date Acquired: #{flight_date.strftime("%d-%^b-%g")}")
                        out_file.puts("")
                        out_file.puts("NRI Sites Acquired:")
                        out_file.puts("")
                        out_file.close

                        # Build the NRI Report
                        obj[:nri][:accepted] = DailyProgressReport.build_project_report flight_date, nri_associated_tiles_not_reported, nri_tiles_not_reported, file_path

                        # push the tiles to the history obj
                        history.tiles << nri_tiles_not_reported

                        out_file = File.open(file_path, "a")
                        out_file.puts("")
                        out_file.puts("=======================")
                        out_file.close
 
                    end

                    # Check if there are SL tiles to report
                    if sl_associated_tiles_not_reported.count > 0

                        # Get the Tiles that match the flight date, even if they have been reported
                        # => Also check the rejected tiles 
                        sl_tiles_not_reported = Tile.sl.flown.where(flight_date: flight_date.strftime("%F")).order(:poly_id)
                        
                        # p "sl_associated_tiles_not_reported #{sl_associated_tiles_not_reported.count}"
                        # p "sl_tiles_not_reported #{sl_tiles_not_reported.count}"

                        # Add the header
                        out_file = File.open(file_path, "a")
                        out_file.puts("========= SL =========")
                        out_file.puts("Subject Line:")
                        out_file.puts("#{flight_date.strftime("%d-%^b-%g")}")
                        out_file.puts("")
                        out_file.puts("Body:")
                        out_file.puts("Date Acquired: #{flight_date.strftime("%d-%^b-%g")}")
                        out_file.puts("")
                        out_file.puts("Easements Acquired:")
                        out_file.puts("")
                        out_file.close

                        # Build the SL Report
                        obj[:sl][:accepted] = DailyProgressReport.build_project_report flight_date, sl_associated_tiles_not_reported, sl_tiles_not_reported, file_path

                        # push the tiles to the history obj
                        history.tiles << sl_tiles_not_reported

                        out_file = File.open(file_path, "a")
                        out_file.puts("")
                        out_file.puts("=======================")
                        out_file.close

                    end

                    out_file.close

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

                    pp obj

                    html = "<p>A Daily Progress report was generated by #{user.first_name} #{user.last_name} for #{flight_date.strftime("%m/%d/%Y")} with #{obj[:nri][:accepted].count} NRI Tiles and #{obj[:sl][:accepted].count} SL Tiles being marked as Approved</p>"
                    # html += "<p>This does not indicate the email was sent to the USDA and it is #{user.first_name} #{user.last_name} responsibility to send.</p>"
                    html += "<p>This report needs to be sent by the person above who generated the report as it contains critical one-time acceptance and rejection information to the USDA. </p>"
                    html += "<hr />"

                    html += "<p>Date Acquired: #{flight_date.strftime("%d-%^b-%g")}</p>"

                    if obj[:nri][:accepted].size > 0
                        html += "<p>NRI Sites Acquired:</p>"
                        obj[:nri][:accepted].each {|item| html += "<pre style='margin: 0;'>#{item}</pre>"}
                        html +="<br/>"
                    end

                    if obj[:sl][:accepted].size > 0
                        html += "<p>Easements Acquired:</p>"
                        obj[:sl][:accepted].each {|item| html += "<pre style='margin: 0;'>#{item}</pre>"}
                        html +="<br/>"
                    end

                    # Log and send email
                    Mailbox.ship({
                        users: MailGroup.find_by(name: "Daily Progress Report").users,
                        subject: "Daily Progress Report was generated - #{flight_date.strftime("%m/%d/%Y")}",
                        message: html
                    })

                end

                obj

            end
        end

    end

    def self.build_project_report flight_date, associated_tiles_not_reported, tiles_not_reported, file_path

        out_file = File.open(file_path, "a")

        records = []

        associated_tiles_not_reported.each do |tile|
            # Update the tile's report date if it's not set
            tile.update(report_date: Time.now) if tile.report_date.nil?

            # Pass to object aray for rendering
            records |= [tile.poly_id]

            # Write to file
            out_file.puts(tile.poly_id)
        end

        # update the tiles to today's date
        tiles_not_reported.each do |tile|
            # Update the tile's report date if it's not set
            tile.update(report_date: Time.now) if tile.report_date.nil?

            # Pass to object aray for rendering
            records |= [tile.poly_id]

            # Write to file
            out_file.puts(tile.poly_id)
        end

        out_file.close

        records

    end

    def self.daily_check

        p "DAILY CHECK - #{Time.now}"

        # Checks if there were any flight dates older than yesterday that have not been reported
        # Also checks if there are any rejections that 
        # does not run on the weekends, only weekdays

        yesterday = Date.yesterday.strftime("%F")
        # yesterday = "2024-04-11"

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
