class Task

    # Send an email to Admins notifying them the email relay still works
    def self.sanity_check

        p "EMAIL SANITY CHECK - #{Time.now}"

        # Log and send email
        Mailbox.ship({
            users: MailGroup.find_by(name: "Email Relay Check").users,
            subject: "Email Relay Sanity Check",
            message: "<p>Email relay is working just fine.</p>"
        })

        # User.admins.each do |user|
        #     PostmasterMailer.notify(user, "<p>Email relay is working just fine.</p>".html_safe, "USDA #{Rails.application.secrets.project_year}: Email Relay Sanity Check").deliver
        # end
    end

    # Converts the Windows path to linux path
    # => Don't use double quotes, use single quotes
    def self.build path
        if path.include? Rails.application.secrets.exe_required
            split = path.strip.gsub('\\','/').split(Rails.application.secrets.exe_required)
            path = "#{Rails.application.secrets.exe_folder}#{split[1]}"
            File.directory?(path) && split.size > 1 ? path : false 
        elsif path.include? Rails.application.secrets.naip_exe_required
            split = path.strip.gsub('\\','/').split(Rails.application.secrets.naip_exe_required)
            path = "#{Rails.application.secrets.naip_exe_folder}#{split[1]}"
            File.directory?(path) && split.size > 1 ? path : false 
        elsif path.include? Rails.application.secrets.vol5_required
            split = path.strip.gsub('\\','/').split(Rails.application.secrets.vol5_required)
            path = "#{Rails.application.secrets.vol5_folder}#{split[1]}"
            File.directory?(path) && split.size > 1 ? path : false 
        else
            false
        end
    end

    def self.update_flight_times

        start_date = Date.tomorrow

        # Destroy in batches anything older than the start date
        FlightTime.where("flight_date < '#{start_date}'").destroy_all

        # Calculate the date range
        # end_date = start_date + 6.days
        # range = start_date..end_date
        
        # Iterate over all the ready to fly tiles and generate the next 7 days of flight times
        Tile.exclude_geom.not_flown.includes(:flight_times).each do |tile|

            # p "TILE: #{tile.poly_id}"
            # p "---------------------------"
            # range.each do |date|
                # p date.strftime("%F")

                # check if the date exists or not
                # if tile.flight_times.where(flight_date: date).empty?
                    # p "- Generate"
                    # Generate the sun angle start/stop imes
                    tile.generate_sun_angles start_date, 6
                # end
            # end
        end        

    end

    # Method only update the 7th flight date after running at 2am every morning
    def self.add_new_flight_time

        p "ADD NEW FLIGHT TIME - #{Time.now}"

        # Destroy in batches anything older than the start date
        FlightTime.where("flight_date < '#{Date.today}'").destroy_all
        
        # Iterate over all the tiles that have not been flown yet
        Tile.exclude_geom.not_flown.includes(:flight_times).each do |tile|

            # Update the 7th flight date
            tile.generate_sun_angles Date.tomorrow + 6.days

        end
    end 

    # Updates the search terms of the Historic Association in case the associations have changed
    def self.update_search_terms

        p "UPDATE SEARCH TERMS - #{Time.now}"

        HistoricAssoc.all.each do |record|
            record.update_search_field
        end
    end

    # Check for easements that are covered by footprints but not marked as flown
    def self.whats_not_flown_but_covered

        Tile.all.update(notes: nil)

        DissolvedFootprint.find_or_create_by(name: "state").update(geom: nil)

        easements = {}
        total = 0

        # Query out all the footprints in a given state and select all Easements that are completely covered yet marked as not flown
        State.active_sl.each do |state|
        # [State.active_sl.first].each do |state|
            p state.name

            easements[state.name] = 0

            # Dissolve all the footprints
            sql = "UPDATE dissolved_footprints SET geom = (SELECT ST_Multi(st_union(ST_Multi(geom::geometry))) AS the_geom from footprints where ST_IsValid(geom::geometry) AND footprints.project = 'SL' AND footprints.state_id = #{state.id}) where name='state'"
            ActiveRecord::Base.connection.execute(sql)

            # Query against the Easements that have not been flown
            Easement.not_flown.includes(:tiles).joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='state' AND st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").each do |easement|
                easements[state.name] += 1
                total += 1
                # easements[state.name] << easement.poly_id
                easement.tiles.update(notes: "Not Flown but Covered")
            end

        end

        p total
        easements

    end

    # Get the files in path
    # => Decided to add a type parameter to differentiate different query types
    def self.get_files_in_path path, type

        if !File.directory?(path)
            p "Invalid Path"
            return false
        end

        result = []

        Dir.glob("#{path}/*.tif") do |file|
            split = File.basename(file, '.tif').split('_')
            if type == "rotate"
                query = {id: split[1]}
            elsif type == "rename"
                query = {frame_no: split[1]}
            end

            record = PostFlightRecord.includes(:roll).where(rolls: {number: split[0]}).where(query).first

            if record.nil?
                roll_number = "NA"
            else
                roll_number = record.roll.respond_to?(:number) ? record.roll.number : "NA"
            end

            obj = {
                match: record.nil? ? false : true,
                roll_number: roll_number,
                record_number: !record.nil? ? record.id : "NA",
                frame_number: !record.nil? ? record.frame_no : "NA",
                name: File.basename(file),
                size: File.size(file),
                last_modified: File.mtime(file)
            }
            result << obj
        end

        result
    end

    # Move Tiffs to UTM Folder structure
    def self.move_tiffs_to_utm params

        output = {
            pass: false,
            message: nil,
            count: 0,
            errors: []
        }

        path = Task.build params[:input_directory]

        if !path
            output[:errors] << "Invalid Input Directory: #{params[:input_directory]}"
            return output
        end

        if !File.directory?(path)
            output[:pass] = false
            output[:errors] << "Invalid Path: #{path}"
            return output
        end

        # Iterate all Tiffs in the input directory
        Dir.glob("#{path}/*.tif") do |file|

            # Get the file name without the extension
            file_name = File.basename(file, '.tif')

            # Find the tile by the filename
            tile = Tile.find_by(filename: file_name)

            # Check if tile is nil
            # => if so then mark it and skip to the next one
            if tile.nil?
                output[:errors] << "File #{File.basename(file)} does not exist in the database"
                output[:pass] = false
                next
            end

            # Build the path
            utm_path = "#{path}/#{tile.utm.zone}"

            # Create a folder if it doesn't exist
            FileUtils.mkdir_p(utm_path) unless File.directory?(utm_path)

            # Take the filename (ignore the extension) and iterate the files in the same path matching the file name
            # => Move all files to the folder
            Dir.glob("#{path}/#{File.basename(file, '.tif')}.*") do |file|
                if File.file?(file)
                    # move the file into the UTM zone folder
                    FileUtils.mv(file, "#{utm_path}/#{File.basename(file)}")
                else
                    output[:errors] << "File #{file_name}.#{ext} does not exist in folder"
                    output[:pass] = false
                end
            end

            output[:count] += 1
        end

        if output[:count] == 0
            output[:errors] << "No Tiffs found in directory"
        end

        if output[:errors].count == 0
            output[:pass] = true
        end

        output

    end

    # Move tiffs out of UTM Folder
    def self.move_tiffs_from_utm params

        output = {
            pass: false,
            message: nil,
            count: 0,
            errors: []
        }

        path = Task.build params[:input_directory]

        if !path
            output[:errors] << "Invalid Input Directory: #{params[:input_directory]}"
            return output
        end

        if !File.directory?(path)
            output[:pass] = false
            output[:errors] << "Invalid Path: #{path}"
            return output
        end

        # Iterate the folders in the path
        Dir.chdir(path) do
            Dir.glob('*').each do |folder|
                # Query the UTM zone by the folder name
                utm = Utm.find_by(zone: folder)
                # If the utm file is not nil then move all the files in the folder
                if utm
                    Dir.glob("#{path}/#{utm.zone}/*") do |file|
                        FileUtils.mv(file, "#{path}/#{File.basename(file)}")
                        output[:count] += 1
                    end

                    # Check if the folder is empty and if so then remove it
                    if Dir["#{path}/#{utm.zone}/*"].empty?
                        FileUtils.rm_rf("#{path}/#{utm.zone}")
                    else
                        output[:pass] = false
                        output[:errors] << "Could not Delete folder: #{path}/#{utm.zone}"
                    end
                end
            end
        end

        if output[:count] == 0
            output[:errors] << "No UTM Folders found in #{params[:input_directory]}"
        end

        if output[:errors].count == 0
            output[:pass] = true
        end

        output

    end

    # def self.find_uncovered_easements

    #     DissolvedFootprint.find_or_create_by(name: "audit").update(geom: nil)
    #     sql = "UPDATE dissolved_footprints SET geom = (SELECT ST_Multi(st_union(ST_Multi(geom::geometry))) AS the_geom from footprints where ST_IsValid(geom::geometry) AND footprints.project = 'SL') WHERE name='audit'"
    #     result = ActiveRecord::Base.connection.execute(sql)
        
    #     easements = []

    #     Easement.flown.joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='audit' AND NOT st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").each do |easement|
    #         p easement.id
    #         easements << easement.id
    #         easement.tiles.update(notes: "No")
    #     end

    #     p easements.count
    #     p easements

    # end

    # def self.find_all_covered_rejections

    #     # Iterate over rejected tiles and get easement
    #     # perform spatial query against footprints that cover it
    #     # Dissolve by Flight Date and check if Easement is covered

    #     output = ""

    #     f = File.open("/media/sf_shared/audit/rejected_but_covered.txt", "w+")

    #     found_poly_ids = []

    #     rejected_poly_ids = RejectedTile.all.pluck(:poly_id).uniq

    #     # rt = RejectedTile.find(88)
    #     Easement.not_flown.where(poly_id: rejected_poly_ids).order(:poly_id).each do |easement|

    #         # Do not include footprints that have flight dates that have already been rejected
    #         no_flight_dates = RejectedTile.where(poly_id: easement.poly_id).pluck(:flight_date).uniq

    #         formatted_flight_dates = no_flight_dates.map {|fd| "fp.flight_date != '#{fd}'"}
    #         # p formatted_flight_dates

    #         # Query against the Footprint geometry scoped based on the previous footprint id array
    #         sql = "SELECT fp.id as fp_id, 
    #                 fp.flight_date as fp_flight_date, 
    #                 fp.flown_by_id as fp_flown_by_id,
    #                 fp.camera_id as fp_camera_id,
    #                 fp.plane_id as fp_plane_id 
    #                 from easements e, footprints fp where st_intersects(e.geom, fp.geom) AND e.id = #{easement.id} AND fp.project='#{easement.project}' AND #{formatted_flight_dates.join(" AND ")} ORDER BY fp.flight_date DESC"
            
    #         results = ActiveRecord::Base.connection.execute(sql)

    #         footprints = {}

    #         results.each do |result|
    #             # p "---"
    #             # p result
    #             # p footprints
    #             # p "---"
    #             footprints["#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"] = {} if footprints["#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"].nil?

    #             if !footprints["#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"][result["fp_flight_date"]]
    #                 footprints["#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"][result["fp_flight_date"]] = {
    #                     flight_date: result["fp_flight_date"],
    #                     fp_flown_by_id: result["fp_flown_by_id"],
    #                     fp_camera_id: result["fp_camera_id"],
    #                     fp_plane_id: result["fp_plane_id"],
    #                     ids: [result["fp_id"]]
    #                 }
    #             else
    #                 footprints["#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"][result["fp_flight_date"]][:ids] << result["fp_id"]
    #             end

    #             # if !footprints["#{result["fp_flight_date"]}_#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"] 
    #             #     footprints["#{result["fp_flight_date"]}_#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"] = {
    #             #         flight_date: result["fp_flight_date"],
    #             #         fp_flown_by_id: result["fp_flown_by_id"],
    #             #         fp_camera_id: result["fp_camera_id"],
    #             #         fp_plane_id: result["fp_plane_id"],
    #             #         ids: [result["fp_id"]]
    #             #     }
    #             # else 
    #             #     footprints["#{result["fp_flight_date"]}_#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"][:ids] << result["fp_id"]
    #             # end

    #         end

    #         p "+++++++++"
    #         pp footprints
    #         p "----"

    #         # Begin dissolve and iteration

    #         easement_output = []
    #         potential_footprints = []

    #         footprints.each do |key, flight_obj|

    #             flight_obj.each do |flight_date, flight|

    #                 p flight_date
    #                 p flight

    #                 DissolvedFootprint.footprints flight[:ids], easement.project

    #                 sql = "SELECT ST_Contains(df.geom::geometry, e.geom::geometry) FROM dissolved_footprints df, easements e WHERE df.name = 'footprints'  AND e.id = #{easement.id}"
    #                 results = ActiveRecord::Base.connection.execute(sql)

    #                 # p results[0]

    #                 if results[0]["st_contains"] == true
    #                     # p "UPDATE"

    #                     footprints = Footprint.select(:id, :strip_frame).order(:strip_frame).where(id: flight[:ids])
    #                     # f.puts "PolyID: #{easement.poly_id} | State: #{footprints.first.state_name} | Flight Date: #{flight_date} | Strip Frames: [#{footprints.pluck(:strip_frame).join(", ")}] \n"
    #                     # output += "PolyID: #{easement.poly_id} ; Flight Date: #{obj[:flight_date]} - [#{obj[:ids].join(", ")}] \n"

    #                     potential_footprints << {flight_date: flight_date, footprints: footprints}

    #                     break

    #                 end

    #             end
    #         end

    #         if potential_footprints.length > 0
    #             f.puts "PolyID: #{easement.poly_id} | State: #{easement.state_name} \n"

    #             potential_footprints.each do |record|

    #                 p record

    #                 f.puts("Flight Date: #{record[:flight_date]} | Strip Frames: #{record[:footprints].pluck(:strip_frame).join(", ")} | IDs: [#{record[:footprints].pluck(:id).join(", ")}]")
    #             end

    #             f.puts("")
    #         end

    #     end

    #     # p output
    #     f.close

    # end

        # def self.test
        
    #     response = {
    #         result: []
    #     }

    #     state = State.find_by(abv: "NJ")
    #     date_flown_from = Time.parse("2022-01-01").utc.beginning_of_day
    #     date_flown_end = Time.parse("2022-09-01").utc.end_of_day

    #     # SL
    #     # Tile.where(state_id: state.id, flight_date: date_flown_from..date_flown_end).select(:flown_by_name, :camera_name, :county_name).distinct.to_a.sort_by(&:county_name).each do |group|

    #     #     # Get the totals
    #     #     scoped_tiles = state.tiles.includes(:easement).where(flight_date: date_flown_from..date_flown_end, flown_by_name: group[:flown_by_name], camera_name: group[:camera_name], county_name: group[:county_name])
    #     #     rejected_tiles = state.rejected_tiles.where(flight_date: date_flown_from..date_flown_end, flown_by_name: group[:flown_by_name], camera_name: group[:camera_name], county_name: group[:county_name])
    #     #     total_flown = scoped_tiles.count + rejected_tiles.count

    #     #     response[:result] << {
    #     #         county_name: group[:county_name],
    #     #         total_flown: total_flown,
    #     #         acres: scoped_tiles.map {|tile| tile.easement.acres}.inject(:+).to_f.round(2),
    #     #         asi_accepted: scoped_tiles.count,
    #     #         asi_rejected: rejected_tiles.count,
    #     #         usda_accepted: scoped_tiles.usda_accepted.count,
    #     #         usda_rejected: scoped_tiles.usda_rejected.count,
    #     #         usda_accepted_percentage: (scoped_tiles.usda_accepted.count.to_f / total_flown * 100).round(2),
    #     #         usda_rejected_percentage: (scoped_tiles.usda_rejected.count.to_f / total_flown * 100).round(2)
    #     #     }

    #     #   end

    #     # NAIP

    #     obj = {}
    #     ids = []

    #     doqq_ids = Doqq.select(:id).where(state_id: state.id, flight_date: date_flown_from..date_flown_end).pluck(:id)
    #     DoqqFootprint.includes(:doqq, :footprint).where(doqq_id: doqq_ids).order("footprints.flown_by_name DESC, camera_name DESC").each do |df|
    #         # Get the associated footprints
    #         # Add the 

    #         next if ids.include? df.doqq.id
            
    #         p df 

    #         obj[df.footprint.flown_by_name] = {} if obj[df.footprint.flown_by_name].nil?


    #         obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"] = {} if obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"].nil?

    #         if obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"].empty?
    #             obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"] = {
    #                 flown_by: df.footprint.flown_by_name,
    #                 camera_name: df.footprint.camera_name,
    #                 total_flown: 1,
    #                 sq_miles: df.doqq.sq_miles,
    #                 asi_accepted: 1,
    #                 asi_rejected: RejectedDoqq.where(qq_apfo_name: df.doqq.qq_apfo_name).count,
    #                 usda_accepted: df.doqq.usda_accepted ? 1 : 0,
    #                 usda_rejected: 0,
    #                 asi_accepted_percentage: 0,
    #                 asi_rejected_percentage: 0,
    #                 usda_accepted_percentage: 0,
    #                 usda_rejected_percentage: 0,
    #             } 
    #         else
    #             obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:total_flown] += 1
    #             obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:sq_miles] += df.doqq.sq_miles
    #             obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:asi_accepted] += 1
    #             obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:asi_rejected] += RejectedDoqq.where(qq_apfo_name: df.doqq.qq_apfo_name).count
    #             obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:usda_accepted] += df.doqq.usda_accepted ? 1 : 0
    #             obj["#{df.footprint.flown_by_id}_#{df.footprint.camera_id}"][:usda_rejected] += 0
    #         end

    #         ids << df.doqq.id

    #     end

    #     result = obj.flatten.select { |record| record.class == Hash && !record.empty? }

    #     result.each do |record|

    #         record[:sq_miles] = record[:sq_miles].to_f.round(2)
    #         record[:asi_accepted_percentage] = (record[:asi_accepted].to_f / record[:total_flown].to_f * 100).round(2)
    #         record[:asi_rejected_percentage] = (record[:usda_rejected].to_f / record[:total_flown].to_f * 100).round(2)
    #         record[:usda_accepted_percentage] =  (record[:usda_accepted].to_f / record[:total_flown] * 100).round(2)
    #         record[:usda_rejected_percentage] = (record[:usda_rejected].to_f / record[:total_flown] * 100).round(2)

    #     end

    #     pp result
        
    #     p "done"
    #     # mismatch = []

    #     # Tile.flown.each do |tile|
    #     #     tile.footprints.where.not(flight_date: tile.flight_date).each do |footprint|
    #     #         mismatch << {
    #     #             tile_id: tile.id,
    #     #             poly_id: tile.poly_id,
    #     #             tile_flight_date: tile.flight_date,
    #     #             footprint_id: footprint.id,
    #     #             footprint_flight_date: footprint.flight_date
    #     #         }
    #     #     end
    #     # end

    #     # p mismatch
    #     # p mismatch.count
    # end


    # def self.audit

    #     # find all Footprints wihtout EOs
    #     # Footprint.left_outer_joins(:frame_center).where(flight_date_time: nil, frame_centers: { id: nil }).count

    #     CSV.open("/media/sf_shared/audit/footprint_uploads_missing_eos.csv", "wb") do |csv|
    #         csv << ["upload_id", "state", "flight_date", "flown_by", "camera", "plane", "total_footprints", "footprints_with_eos", "footprint_missing_eo"]
    #         Upload.includes(:footprints).where(upload_type: "Footprint").each do |upload|

    #             # Check if the uploads are SL
    #             next if upload.footprints.first.project == "NAIP"

    #             first = upload.footprints.first
        
    #             # Check if all the Footprints have a flight date time
    #             if upload.footprints.has_flight_date_time.count > 0 && (upload.footprints.count != upload.footprints.has_flight_date_time.count)

    #                 csv << [upload.id, first.state_name, first.flight_date, first.flown_by_name, first.camera_name, first.plane_name, upload.footprints.count,
    #                     upload.footprints.has_flight_date_time.count, (upload.footprints.count - upload.footprints.has_flight_date_time.count)]

    #             end

    #         end
    #     end


    #     CSV.open("/media/sf_shared/audit/strip_frames_missing_eos.csv", "wb") do |csv|
    #         csv << ["footprint_id", "state", "county", "flight_date", "strip_frame", "flown_by", "camera", "plane", "upload_id"]
    #         Upload.includes(:footprints).where(upload_type: "Footprint").each do |upload|

    #             # Check if the uploads are SL
    #             next if upload.footprints.first.project == "NAIP"

    #             first = upload.footprints.first

    #             # Check if all the Footprints have a flight date time
    #             if upload.footprints.has_flight_date_time.count > 0 && (upload.footprints.count != upload.footprints.has_flight_date_time.count)

    #                 upload.footprints.where(flight_date_time: nil).each do |footprint|
                    
    #                     csv << [footprint.id, footprint.state_name, footprint.county_name, footprint.flight_date, footprint.strip_frame, 
    #                         footprint.flown_by_name, footprint.camera_name, footprint.plane_name, upload.id]

    #                 end

    #             end

    #         end
    #     end

    #     # # Find all footprints that have the same footprint centroids
    #     CSV.open("/media/sf_shared/audit/duplicate_footprint_centroids.csv", "wb") do |csv|
    #         csv << ["footprint_id", "strip_frame", "flight_date", "state", "county_name", "flown_by", "camera", "plane", "upload_id"]

    #         Footprint.sl.select(:centroid_latitude,:centroid_longitude).group(:centroid_latitude,:centroid_longitude).having("count(*) > 1").all.each do |fp|
    #             Footprint.where(centroid_longitude: fp.centroid_longitude, centroid_latitude: fp.centroid_latitude).each do |footprint|
    #                 csv << [footprint.id, footprint.strip_frame, footprint.flight_date, footprint.state_name, footprint.county_name, footprint.flown_by_name, footprint.camera_name, footprint.plane_name, footprint.upload_id]
    #             end
    #         end
    #     end

    #     # Find all easements that are covered by multiple flight dates
    #     CSV.open("/media/sf_shared/audit/easements_with_coverage_of_multiple_flight_dates.csv", "wb") do |csv|
    #         csv << ["easement_id", "poly_id", "easement_flight_date", "flight_date_coverage", "state", "county"]

    #         # Get the footprint flight dates
    #         flight_date = Footprint.sl.order(:flight_date).pluck(:flight_date).uniq

    #         # Create the audit layer if it doesn't exist
    #         DissolvedFootprint.find_or_create_by(name: "audit").update(geom: nil)

    #         flight_date.each do |flight_date|
    #             p flight_date

    #             # Dissolve by flight_date
    #             sql = "UPDATE dissolved_footprints SET geom = (SELECT ST_Multi(st_union(ST_Multi(geom::geometry))) AS the_geom from footprints where ST_IsValid(geom::geometry) AND footprints.project = 'SL' AND footprints.flight_date = '#{flight_date.strftime("%F")}') WHERE name='audit'"
    #             result = ActiveRecord::Base.connection.execute(sql)

    #             Easement.includes(:state, :county).where.not(flight_date: flight_date).joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='audit' AND st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").each do |easement|
    #                 csv << [easement.id, easement.poly_id, easement.flight_date, flight_date, easement.state.name, easement.county.name]
    #             end

    #         end

    #         DissolvedFootprint.find_by(name: "audit").delete
    #     end

    #     p "done"

    # end

end