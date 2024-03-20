class WeeklyProgressReport

    def self.generate project, user=User.first
        if project == "NRI"
            states = State.active_nri.exclude_geom.includes(:tiles)
        elsif project == "SL"
            states = State.active_sl.exclude_geom.includes(:tiles)
        else
            return {state: false, message: "Invalid Project: #{project}"}
        end

         # Create the new excel file and intiailizte the workbook
         package = Axlsx::Package.new
         wb = package.workbook

         # Global Styles
         header_background = wb.styles.add_style(bg_color: "5c8a5c", fg_color: "FFFFFF")

         # create new worksheet
         wb.add_worksheet(name: "Weekly Progress Report") do |sheet|

            sheet.merge_cells "B1:E1"
            sheet.merge_cells "J1:L1"
            sheet.merge_cells "F1:F2"
            sheet.merge_cells "G1:G2"
            sheet.merge_cells "H1:H2"
            sheet.merge_cells "I1:I2"

            current_time = Time.now.strftime("%d/%m/%Y")

            sheet.add_row [
                "As of:", 
                current_time, nil, nil, nil,
                "Anticipated Final Delivery",
                "Season Dates",
                "Season Extensions",
                "State Priorty",
                "Issues", nil, nil
            ]
            sheet.add_row [
                "State",
                "Total Easements",
                "Total Flown",
                "Percent",
                "Percent Delivered",nil, nil, nil, nil, 
                "Weather",
                "Military",
                "Other",
            ]

            states.each do |state|

                p state.name

                contract = state.contract_awards.find_by(project: project)

                count = state.tiles.count
                flown_count = state.tiles.flown.count
                percentage_flown = state.tiles.flown.count.to_f / state.tiles.count.to_f * 100
                percentage_delivered = state.tiles.shipped.count.to_f / state.tiles.count.to_f * 100

                season_dates = contract.season_start && contract.season_end ? "#{contract.season_start.strftime("%m/%d")} - #{contract.season_end.strftime("%m/%d")}" : nil
                season_extension = contract.season_extension.nil? ? nil : "Approved #{contract.season_extension.strftime("%d/%m")}"

                sheet.add_row [
                    state.name,
                    count,
                    flown_count,
                    percentage_flown,
                    percentage_delivered,
                    nil,
                    season_dates,
                    season_extension
                ]

            end

            # Write to output
            path = Rails.root.join('assets', 'weekly_progress_reports')
            Dir.mkdir(path) unless File.directory?(path)
            timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
            filename = "USDA #{project} #{Rails.application.secrets.project_year} Weekly Progress Report (#{timestamp}).xlsx"
            package.serialize("#{path}/#{filename}")

            # copy file to p drive
            FileUtils.cp("#{path}/#{filename}", "#{Rails.application.secrets.weekly_progress_folder}#{filename}")

            # Create a new History record
            history = History.new
            history.message = "Generated new #{project} Weekly Progress Report"
            history.url = "#{path}/#{filename}"
            history.action_type = "Weekly Progress Report"
            history.creator = user
            history.save

            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Daily Progress Report").users,
                subject: "#{project} Weekly Progress Report was generated - #{Time.now.strftime("%m/%d/%Y")}",
                message: "#{user.full_name} generated a copy of the report and can be downloaded with the link below.",
                route: Rails.application.routes.url_helpers.show_timeline_url(history.id, only_path: false, host: Rails.application.secrets.host)
            })

            return {state: true, id: history.id, message: "Successfully generated report and download is started"}

        end



    end

end