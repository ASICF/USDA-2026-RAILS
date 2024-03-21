class Audit

    def self.validate_footprint_upload id=nil

        # Builld the obj if hte id exists
        obj = id.nil? ? {} : {id: id}

        # Track errors
        errors = []

        # Query and iterate the footprint impor tuploads
        Upload.footprint_import.where(obj).each do |upload|

            # Get the first footprint
            first = upload.footprints.first

            # Get counts
            scoped_count = upload.footprints.where(flight_date: first.flight_date, plane_id: first.plane_id, camera_id: first.camera_id, flown_by_id: first.flown_by_id, project: first.project, project_state_id: first.project_state_id).count
            upload_count = upload.footprints.count

            # Check if the footprints count match the same values of the first
            if scoped_count != upload_count

                # add to errors
                errors << "Footprint Upload #{upload.id} contained mulitple different attributes"
            end

        end

        errors

    end

    def self.quick_audit
        # Tiles
        easement_flight_date = []
        filename_mismatch = []
        dup_tile_poly_ids = []
        dup_easement_poly_ids = []
        easement_tile_poly_id_mismatch = []
        no_footprints = []
        footprints_not_marked_as_associated_from_tiles = []
        flown_tiles_no_contract_rates = []

        # Footprints
        footprints_marked_as_associated = []
        footprints_not_marked_as_associated = []

        begin

        # Iterate the flown tiles
        Tile.includes(:easement, :footprints).where("updated_at >= '#{Time.now - 65.minutes}'").each do |tile|

            # check if there is duplicate poly_ids
            if Tile.where(poly_id: tile.poly_id).count > 1
                dup_tile_poly_ids << tile.poly_id
            end

            # check if the easement has the same poly_id
            if tile.easement.poly_id != tile.poly_id
                easement_tile_poly_id_mismatch << tile.poly_id
            end

            # Check if the there is a duplicate poly_id in the easements layer
            if Easement.where(poly_id: tile.poly_id).count > 1
                dup_easement_poly_ids << tile.poly_id
            end

            # Only if the tile is marked as flown
            if tile.flown

                # check if the flight dates between easement and tile match
                if tile.easement.flight_date != tile.flight_date
                    easement_flight_date << tile.poly_id
                end

                # flown tile should have footprints
                if tile.footprints.count == 0
                    tile.update(review_desc: "Error! Tile marked as flown but no associated Footprints")
                    no_footprints << tile.poly_id
                end

                # flown tile should have footprints
                if tile.footprints.where(associated: false).count > 0
                    tile.update(review_desc: "Error! Tile's Footprints are not marked as associated")
                    footprints_not_marked_as_associated_from_tiles << {poly_id: tile.poly_id, strip_frames: tile.footprints.where(associated: false).pluck(:strip_frame)}
                end

                # Validate the tile filename
                if tile.filename != tile.build_filename
                    tile.update(review_desc: "Error! Invalid Filename! Should be #{tile.build_filename} instead #{tile.filename}")
                    filename_mismatch << tile.poly_id
                end

                # check if the rates are set or not
                if tile.total_amount.nil?
                    tile.set_contract_rate
                    tile.update(review_desc: "Tile was marked as flown but did not have contract rates set")
                    flown_tiles_no_contract_rates << tile.poly_id
                end
            end
        end

        Footprint.includes(:tiles, :frame_center).where("updated_at >= '#{Time.now - 65.minutes}'").each do |footprint|

            # Validate the tile filename
            if footprint.associated && footprint.tiles.count == 0
                footprint.update(review_desc: "Footprint is marked as associated but does not have an associated Tile")
                footprints_marked_as_associated << "Strip Frame: #{footprint.strip_frame}, Flown by #{footprint.flown_by_alias}, Flight Date #{footprint.flight_date.strftime("%m/%d/%Y")}"
            end

            if !footprint.associated && footprint.tiles.count > 0
                footprint.update(review_desc: "Footprint is not marked as associated but has associated Tile")
                footprints_not_marked_as_associated << "Strip Frame: #{footprint.strip_frame}, Flown by #{footprint.flown_by_alias}, Flight Date #{footprint.flight_date.strftime("%m/%d/%Y")}, Tiles: #{footprint.tiles.pluck(:poly_id).join(", ")}"
            end

        end

        # Add test for long running Jobs
        # => If the started_at time is past an hour after starting then cancel it and send email to Creator and Admin
        if Job.active.where("jobs.started_at < ? AND jobs.finished_at IS NULL", Time.now - 2.hours).count > 0
            # Cancel the job
            Job.active.where("jobs.started_at < ? AND jobs.finished_at IS NULL", Time.now - 2.hours).each do |job|
                job.update(
                    finished_at: Time.now,
                    message: nil,
                    active: false,
                    success: false,
                    error_message: "Job was running for over an hour and has been terminated. This does not necessarily mean the Job is not still running."
                )
                
                # Log and send email
                Mailbox.ship({
                    users: MailGroup.find_by(name: "Errors").users + [job.creator],
                    subject: "Long running Job detected",
                    message: "The Job \"#{job.process_type}\" submitted at #{job.created_at.strftime("%m/%d/%Y %I:%M %p")} has been cancelled due to it running over an hour since starting. This does not mean the process has necessarily failed but may imply that the process encountered an error that was not caught by the exception handlers. Check the QGIS Project or Reports to see if the database was updated."
                })

                # # Send email to the creator and the admins
                # users = User.admins.map {|user| user} + [job.creator]
                # users.uniq.each do |user|
                #     PostmasterMailer.notify(user, "The Job \"#{job.process_type}\" submitted at #{job.created_at.strftime("%m/%d/%Y %I:%M %p")} has been cancelled due to it running over an hour since starting. This does not mean the process has necessarily failed but may imply that the process encountered an error that was not caught by the exception handlers. Check the QGIS Project or Reports to see if the database was updated.", "USDA #{Rails.application.secrets.project_year}: Long running Job detected").deliver
                # end

            end
        end

        # Check if the delayed job is running or not
        # => If it is not and rails is in production mode, then start it up
        if !system('ps -ef | grep "\bdelayed_job\b"') && Rails.env.production?
            begin
                system('RAILS_ENV=production bin/delayed_job start')

                # Create a new History record
                history = History.new
                history.message = "Started backend Delayed Job Service"
                history.action_type = "System Routines"
                history.creator = User.admins.first
                history.save
                
                # Log and send email
                Mailbox.ship({
                    users: MailGroup.find_by(name: "Errors").users,
                    subject: "Started Delayed Job Service",
                    message: "Delayed Job Service was not running, it has been started automatically by the App."
                })

                # # Email
                # User.admins.each do |user|
                #     PostmasterMailer.notify(user, "Delayed Job Service was not running, it has been started automatically by the App.", "USDA #{Rails.application.secrets.project_year}: Started Delayed Job Service").deliver
                # end

            rescue => exception
                # Log and send email
                Mailbox.ship({
                    users: MailGroup.find_by(name: "Errors").users,
                    subject: "Error starting Delayed Job Service",
                    message: "Delayed Job is not actively running and could not start the service automatically from app."
                })

                # # Email
                # User.admins.each do |user|
                #     PostmasterMailer.notify(user, "Delayed Job is not actively running and could not start the service automatically from app.", "USDA #{Rails.application.secrets.project_year}: Error Starting Delayed Job Service").deliver
                # end
            end
        end

        # Only send the mail between 6am and 10pm
        from = Time.parse("7am")
        to = Time.parse("10pm")

        # Check if within time range
        if (from..to).include? Time.now

            email_output = ["Errors were detected in the Quick Database Audit. Due to the severity of the issue, this message will continue to be sent until fixed."]

            # Check if the easement count matches the contract totals
            if Easement.count != Rails.application.secrets.sl_contract_easements || Tile.count != Rails.application.secrets.sl_contract_easements
            
                html = "<p>There is a mismatch within the Database and our contracted totals.</p>"
                html += '<ul>'
                if Easement.count != Rails.application.secrets.sl_contract_easements
                    html += "<li>Easement count does not match our contracted totals. #{Easement.count} out of #{Rails.application.secrets.sl_contract_easements}</li>"
                end
                if Easement.count != Rails.application.secrets.sl_contract_easements
                    html += "<li>Tile count does not match our contracted totals. #{Tile.count} out of #{Rails.application.secrets.sl_contract_easements}</li>"
                end
                html += '</ul>'

                email_output << html
            end

            # If there is a duplicate polyid then send out an email
            if easement_flight_date.count > 0

                html = "<p>There are mismatches between the Easement and Tile Flight Dates.</p>"
                html += '<ul>'
                easement_flight_date.each do |poly_id|
                    html += "<li>#{poly_id}</li>"
                end
                html += '</ul>'

                email_output << html
            end

            # If there is a duplicate polyid then send out an email
            if dup_tile_poly_ids.count > 0

                html = "<p>There are duplicate PolyIDs in the Tile Layer.</p>"
                html += '<ul>'
                dup_tile_poly_ids.uniq.each do |poly_id|
                    html += "<li>#{poly_id}</li>"
                end
                html += '</ul>'

                email_output << html
            end

            # If there is a duplicate polyid then send out an email
            if dup_easement_poly_ids.count > 0

                html = "<p>There is a duplicate PolyIDs in the Easement Layer.</p>"
                html += '<ul>'
                dup_easement_poly_ids.uniq.each do |poly_id|
                    html += "<li>#{poly_id}</li>"
                end
                html += '</ul>'

                email_output << html
            end

            # If there is a duplicate polyid then send out an email
            if easement_tile_poly_id_mismatch.count > 0

                html = "<p>There is a mismatched PolyID between the Easement and associated Tile.</p>"
                html += '<ul>'
                easement_tile_poly_id_mismatch.uniq.each do |poly_id|
                    html += "<li>#{poly_id}</li>"
                end
                html += '</ul>'

                email_output << html
            end

            # If there is any filename mistmatches then send an email
            if filename_mismatch.count > 0

                html = "<p>There are mismatched filenames in the Tiles that need to be fixed.</p>"
                html += '<ul>'
                filename_mismatch.each do |poly_id|
                    html += "<li>#{poly_id}</li>"
                end
                html += '</ul>'

                email_output << html
            end


            # If there is any filename mistmatches then send an email
            if flown_tiles_no_contract_rates.count > 0

                html = "<p>There were Flown Tiles that did not have the Contract Rate set. The Quick Audit updated these values.</p>"
                html += '<ul>'
                flown_tiles_no_contract_rates.each do |poly_id|
                    html += "<li>#{poly_id}</li>"
                end
                html += '</ul>'

                email_output << html
            end

            # If there is any filename mistmatches then send an email
            if no_footprints.count > 0

                html = "<p>There are Tiles marked as Flown but don't have any associated Footprints.</p>"
                html += '<ul class="ui list">'
                no_footprints.each do |poly_id|
                    html += "<li>#{poly_id}</li>"
                end
                html += "</ul>"

                email_output << html
            end

            if footprints_not_marked_as_associated_from_tiles.count > 0

                html = "<p>There are Footprints that are associated to Tiles but not marked as Assocaited in the database.</p>"
                
                footprints_not_marked_as_associated_from_tiles.each do |record|
                    html += '<ul class="ui list">'
                    html += "<li><b>#{record[:poly_id]}</b></li>"

                        html += '<ul class="ui list">'
                        record[:strip_frames].each do |strip_frame|
                            html += "<li>#{strip_frame}</li>"
                        end
                        html += "</ul>"

                    html += "</ul>"
                end

                email_output << html

            end

            if footprints_marked_as_associated.count > 0

                html = "<p>There are Footprints that are marked as Associated but do not have associations to the Tile</p>"
                html += '<ul class="ui list">'
                footprints_marked_as_associated.each do |record|
                    html += "<li>#{record}</li>"
                end
                html += "</ul>"

                email_output << html

            end

            if footprints_not_marked_as_associated.count > 0

                html = "<p>There are Footprints that are not marked as Associated but have associations to the Tile</p>"
                html += '<ul class="ui list">'
                footprints_not_marked_as_associated.each do |record|
                    html += "<li>#{record}</li>"
                end
                html += "</ul>"

                email_output << html

            end

            if email_output.count > 1
                # Log and send email
                Mailbox.ship({
                    users: MailGroup.find_by(name: "Errors").users,
                    subject: "Severe Error Detected!",
                    message: email_output.join("<hr />").html_safe
                })

                # Rails.application.secrets.error_users.each do |user|
                #     next if User.find_by(user).nil?
                #     PostmasterMailer.notify(User.find_by(user), email_output.join("<hr />").html_safe, "USDA #{Rails.application.secrets.project_year}: Severe Error Detected!").deliver
                # end
            end

        end
        rescue => e
            # send email if for some reason the quick audit fails
            Mailbox.ship({
                users: MailGroup.find_by(name: "Errors").users,
                subject: "Quick Audit Failed to Validate",
                message: "Could not validate the Quick Audit due to unexpected error below.<br/><br/>#{e.message}"
            })
        end
    end

    def self.nightly_audit

        p "NIGHTLY AUDIT - #{Time.now}"

        # Iterate all Flown Tiles with multiple Footprints
        # Make sure the associated Footprints have the same flight date as the tile
        # Build the filename dynamically and check it against the stored value


        # Update
        # Easements
        # => Check if the Tile's PolyID is the same as the Easement
        # => Check that the flight dates are the same

        # Tiles
        # => If marked as covered then it's associated footprints should completely cover it
        






        # Reset the review_desc fields to nil for fresh errors
        Footprint.where.not(review_desc: nil).update_all(review_desc: nil)
        Tile.where.not(review_desc: nil).update_all(review_desc: nil)
        FrameCenter.where.not(review_desc: nil).update_all(review_desc: nil)

        error = {
            footprint_association_error: [],
            tile_footprint_flight_date_mismatch: [],
            frame_center_errors: {
                "Frame Centers with no Associated Footprints": 0,
                "Frame Centers with Associated Footprints that do not have matching Strip Frame": 0,
                "Frame Center's associated footprint has a different Flight Date": 0,
                "Frame Centers have different Company than associated Footprints": 0,
                "Frame Centers associated footprint has a different Flight Date": 0,
                "Frame Centers have different Camera than associated Footprints": 0
            },
        }

        # Iterate the flown tiles
        Tile.flown.each do |tile|

            # Check if all the frame center flight dates are within the same day
            fc_flight_dates = []

            tile_review_desc = tile.review_desc.present? ? [tile.review_desc] : []

            # check if the easement and tile has the same flight date
            if tile.easement.flight_date != tile.flight_date
                tile_review_desc << "Tile has different Flight Date than Easement"
            end

            # flown tile should have footprints
            if tile.footprints.where(associated: false).count > 0
                tile.update(review_desc: "Error! Tile's Footprints are not marked as associated")
            end

            # iterate the footprints that are associated but do not have the same flight date
            tile.footprints.each do |footprint|
                # Build notes array
                review_desc = footprint.review_desc.present? ? [footprint.review_desc] : []

                # check if the footprint doesn't have a frame center
                if footprint.frame_center.nil?
                    review_desc |= ["No Frame Center Found"]
                else
                    fc_flight_dates << footprint.frame_center.flight_date
                end

                # Check if the Tile and Footprint have the same Flown By
                if footprint.flown_by_id != tile.flown_by_id
                    review_desc << "Footprint has different Flown By Company than Tile (Poly ID: #{tile.poly_id})"
                    tile_review_desc << "Tile has different Flown By Company than Footprint (Footprint ID: #{footprint.id})"
                end

                # Check if the Tile and Footprint have the same Camera
                if footprint.camera_id != tile.camera_id
                    review_desc << "Footprint has different Camera than Tile (Poly ID: #{tile.poly_id})"
                    tile_review_desc << "Tile has different Camera than Footprint (Footprint ID: #{footprint.id})"
                end

                # Check if the Tile and Footprint have the same Plane
                if footprint.plane_id != tile.plane_id
                    review_desc << "Footprint has different Plane than Tile (Poly ID: #{tile.poly_id})"
                    tile_review_desc << "Tile has different Plane than Footprint (Footprint ID: #{footprint.id})"
                end

                # Update the footprint's review_desc to reference the mismatch
                if footprint.flight_date != tile.flight_date
                    error[:tile_footprint_flight_date_mismatch] << {
                        poly_id: tile.poly_id,
                        tile_flight_date: tile.flight_date,
                        footprint_id: footprint,
                        footprint_flight_date: footprint.flight_date,
                    }
                    review_desc << "Associated Tile has different flight date. (PolyID: #{tile.poly_id} Flight Date: #{tile.flight_date.strftime("%m/%d/%Y")})"
                    tile_review_desc << "Associated Footprint has different flight date. (PolyID: #{tile.poly_id} Flight Date: #{footprint.flight_date.strftime("%m/%d/%Y")})"
                end

                # CHeck if the footprints are not marked as associated
                if !footprint.associated
                    review_desc << "Marked as not associated yet associated to Tile"
                    tile_review_desc << "Associated Footprints Associated field is set to false"
                    error[:footprint_association_error] << {id: footprint.id, strip_frame: footprint.strip_frame, flight_date: footprint.flight_date.strftime("%m/%d/%Y")}
                end

                if review_desc.size > 0
                    footprint.update(review_desc: review_desc.join(", "))
                end
            end

            # check if all the frame center flight dates are within the same day
            if fc_flight_dates.map { |flight_date| flight_date.to_date }.uniq.count > 1
                tile_review_desc << "Tile Median Flight Date references Frame Centers with Flight Dates not contained to a single day."
            end

            # Check if the median flight date (if it exists) is within the minimum sun angle requirements
            if tile.median_flight_date_time 
                # # Get the sun angle 
                elevation, azimuth = Solar.position(tile.median_flight_date_time, tile.easement.longitude, tile.easement.latitude)

                if elevation <  Rails.application.secrets.min_sun_angle
                    tile_review_desc << "Median Flight Date Time Sun Angle (#{elevation}) is below required minimum sun angle (#{Rails.application.secrets.min_sun_angle})"
                end
            end

            # Update the review description
            # => if there is an error/warning then overwrite the tile's review dec
            # => if there is no error/warning but the tile's review_desc is set then revert it to nil (clearing the warning/error)
            if tile_review_desc.size > 0
                tile.update(review_desc: tile_review_desc.join(", "))
            end
        end

        # iterate all counties that tiles are marked as fully flown but not shipped
        # => verify all the county_flown_dates are the same
        county_errors = []
        County.tiles_flown_but_not_shipped_sl.each do |county_id|
            county = County.includes(:tiles).find_by(id: county_id)

            review_desc = []

            # check that all the tiles have a county flown date set
            if county.tiles.county_flown.count != county.tiles.count
                review_desc << "County Tiles are not all fully marked as Flown"
            end

            # pull the unique county flown dates
            county_flown_dates = county.tiles.county_flown.pluck(:county_flown_date).uniq

            # if there is more than one then there is something wrong
            review_desc << "Multiple County Flown Dates found" if county_flown_dates.size > 1

            # check that all the tiles have a county flown date set
            if county.tiles.county_due_set.count != county.tiles.count
                review_desc << "County Tiles are not all fully marked as Due"
            end

            # pull the unique county flown dates
            county_due_dates = county.tiles.county_due_set.pluck(:county_due_date).uniq

            # if there is more than one then there is something wrong
            review_desc << "Multiple County Due Dates found" if county_due_dates.size > 1

            if review_desc.size > 0
                county_errors << "#{county.name}, #{county.state.name}: #{review_desc.join(", ")}"
                county.tiles.each do |tile|
                    tile_review_desc = tile.review_desc.nil? ? [] : [tile.review_desc]
                    tile_review_desc = tile_review_desc + review_desc
                    p tile_review_desc
                    tile.update(review_desc: tile_review_desc.join(", "))
                end
            end
        end

        # if there is an error then iterate and send as mail
        if county_errors.size > 0

            html = "<p>There are discrepencies with Tiles marked as fully flown and/or Due Dates.</p>"
            html += '<ul class="ui list">'
            county_errors.each do |record|
                html += "<li>#{record}</li>"
            end
            html += '</ul>'


            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Audit").users,
                subject: "Nightly Audit Error! Tile mismatch on County Fully Flown Dates and/or County Due Dates",
                message: html
            })
        end

        # iterate the Frame Centers
        FrameCenter.all.each do |fc|

            review_desc = fc.review_desc.present? ? [fc.notes] : []

            # check if the frame center has a footprint
            if fc.footprint.nil?
                review_desc << "No associated Footprint Found" 
                error[:frame_center_errors][:"Frame Centers with no Associated Footprints"] += 1
                # skip going forward since it checks against the footprint and there is no association
                next
            end

            # get the associated footprint
            footprint = fc.footprint

            # Check if the footprint and frame centers actually match
            if footprint.strip_frame != fc.strip_frame 
                review_desc << "Associated Footprint does not have matching Strip Frame"
                error[:frame_center_errors][:"Frame Centers with Associated Footprints that do not have matching Strip Frame"] += 1
            end

            # Check if the flight date matches
            if fc.flight_date.to_date != footprint.flight_date
                review_desc << "Associated Footprint does not have matching Flight Date"
                error[:frame_center_errors][:"Frame Centers associated footprint has a different Flight Date"] += 1
            end

            # check if the company matches
            if fc.flown_by_id != footprint.flown_by_id
                review_desc << "Associated Footprint does not have matching Company"
                error[:frame_center_errors][:"Frame Centers have different Company than associated Footprints"] += 1
            end

            # check if the company matches
            if fc.camera_id != footprint.camera_id
                review_desc << "Associated Footprint does not have matching Camera"
                error[:frame_center_errors][:"Frame Centers have different Camera than associated Footprints"] += 1
            end

            # Update the review description
            # => if there is an error/warning then overwrite the frame center's review dec
            # => if there is no error/warning but the frame center's review_desc is set then revert it to nil (clearing the warning/error)
            if review_desc.size > 0
                fc.update(review_desc: review_desc.join(", "))
            end

        end

        if error[:frame_center_errors][:"Frame Centers with no Associated Footprints"] > 0 || 
            error[:frame_center_errors][:"Frame Centers with Associated Footprints that do not have matching Strip Frame"] > 0 || 
            error[:frame_center_errors][:"Frame Center's associated footprint has a different Flight Date"] > 0 || 
            error[:frame_center_errors][:"Frame Centers have different Company than associated Footprints"] > 0 ||
            error[:frame_center_errors][:"Frame Centers have different Camera than associated Footprints"] > 0

            html = "<p>This email is to alert there are errors found within the Frame Centers. These checks are ran every night to insure database integrity. Unless the errors are addressed, they will continue to send daily.</p>"
            html += '<ul class="ui list">'
            error[:frame_center_errors].each do |key, value|
                if value > 0
                    html += "<li>#{key}: #{value}</li>"
                end
            end
            html += '</ul>'

            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Audit").users,
                subject: "Nightly Audit Error! Frame Center Errors Found",
                message: html.html_safe
            })

        end

        # query any footprints that are not marked as associated but have tiles associated
        # association_error = []
        # Footprint.left_outer_joins(:tiles).where.not(tiles: {id: nil}).each do |footprint|
        #     if !footprint.associated
        #         footprint.update(review_desc: ["Footprint has associated Tile but not marked as Associated in table", footprint.review_desc].join(", "))
        #         association_error << {id: footprint.id, strip_frame: footprint.strip_frame, flight_date: footprint.flight_date.strftime("%m/%d/%Y")}
        #     end

        #     if footprint.flight_date != record["flight_date"]
        #         # update the footprint if the flight date is different than footprint
        #         footprint.update(review_desc: ["Footprint covers easement but has different Flight Date (PolyID: #{record['poly_id']} Flight Date: #{record['flight_date']})", footprint.review_desc].join(", "))
        #     end
        # end

        # Build an email and send if there are footprints associated without 
        if error[:footprint_association_error].size > 0

            html = "<p>There are Footprints that have table associations to the Tiles records but is not marked as Associated in the System.</p>"
            html += '<ul class="ui list">'
            error[:footprint_association_error].each do |record|
                html += "<li>id: #{record[:id]} - Strip Frame: #{record[:strip_frame]} - Flight Date: #{record[:flight_date]}</li>"
            end
            html += '</ul>'

            # Log and send email
            Mailbox.ship({
                users: MailGroup.find_by(name: "Audit").users,
                subject: "Nightly Audit Error! Footprint Association Errors Found",
                message: html.html_safe
            })
        end

        # Log and send email
        Mailbox.ship({
            users: MailGroup.find_by(name: "Audit").users,
            subject: "Nightly Audit Completed",
            message: "<p>Nightly Audit Finished at #{Time.now.strftime("%m/%d/%Y %I:%M %p")}</p>".html_safe
        })

    end

end