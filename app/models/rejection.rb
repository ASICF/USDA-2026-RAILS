class Rejection
    include Rails.application.routes.url_helpers
    # include Concerns::Archive

    def self.import params, user
        # create an Error array to hold any messages
        output = {
            pass: false,
            errors: [],
            count: 0
        }

        # Start a Transaction Block
        ActiveRecord::Base.transaction do
            begin

                # Get the folder name by converting the current time to seconds
                folder = Time.now.to_i

                path = "#{Rails.root}/assets/rejections/#{folder}"

                # Create a folder if it doesn't exist
                FileUtils.mkdir_p("#{path}/projected") unless File.directory?(path)

                # Used to make sure the required files are found
                txt = false

                # Should only accept text file
                if File.extname(params[:file].original_filename) != ".txt" 
                    raise Exception, "Only Text files are supported"
                end

                # Move the file
                FileUtils.mv params[:file].tempfile, "#{path}/#{params[:file].original_filename}"

                # Create upload instance to track the easements created
                upload = Upload.create(
                    folder_path: "#{path}/#{params[:file].original_filename}",
                    upload_type: "Rejected Tile",
                    uploader: user
                )

                # Get the first text file
                txt = Dir.glob("#{path}/#{params[:file].original_filename}").first

                if txt.empty?
                    output[:errors] << "Could not find text file to upload"
                    FileUtils.rm_rf(path)
                    return output, upload
                end

                # Create a new History record
                history = History.new
                history.action_type = "Rejected Tiles"
                history.creator = user
                history.save

                flight_date = params[:flight_date]
                poly_ids = []

                # Open the file
                File.open(txt, "r") do |f|
                    # Iterate each line
                    f.each_line do |line|

                        # set the default polyid and message
                        poly_id = nil
                        message = "Manual Rejection"

                        p "-----------------"
                        p line.strip

                        # # Try to split the line by space
                        # if line.strip.split(" ").size == 1
                        #     p "- no message"
                        #     poly_id = line.strip
                        # elsif line.strip.split(" ").size == 2
                        #     p "- two strings, one space"
                        #     poly_id = line.strip.split(" ")[0].strip
                        #     message = line.strip.split(" ")[1].strip.gsub('"', '').gsub("'", '')
                        # elsif line.strip.split('"').size == 2
                        #     p "- two strings wrapped by quotes"
                        #     poly_id = line.strip.split('"')[0].strip
                        #     message = line.strip.split('"')[1].strip.gsub('"', '')
                        # elsif line.strip.split("'").size == 2
                        #     p "- two strings wrapped by apostrophe"
                        #     poly_id = line.strip.split("'")[0].strip
                        #     message = line.strip.split("'")[1].strip.gsub("'", '')
                        # elsif line.strip.split(" ").size > 1
                        #     p " - Too many array items, ignore message"
                        #     poly_id = line.strip.split(" ")[0].strip
                        # end

                        arr = line.strip.split(" ")

                        if arr.size == 1
                            p "- no message"
                            poly_id = line.strip
                        else
                            poly_id = arr[0].strip
                            message = arr.drop(1).join(" ").gsub('"', '').gsub("'", '')
                        end

                        p " - - - "
                        p "poly_id: #{poly_id}"
                        p "message: #{message}"

                        # Get the tile, only should be one
                        tile = Tile.flown.find_by(
                            poly_id: poly_id, 
                            flight_date: flight_date
                        )

                        p "tile: #{tile}"
                        p ""

                        # If present then push the Tile id to an array
                        if tile.present?
                            # poly_ids << tile.poly_id
                            rejection_output, history = Rejection.reject_tiles [poly_id], flight_date, history, false, message
                            # Set the count
                            output[:count] += rejection_output[:count]
                        end
                    end
                end

                # Reject the tiles
                # rejection_output, history = Rejection.reject_tiles poly_ids, flight_date, history

                # Set the count
                # output[:count] = rejection_output[:count]

                p "+_+_+_+_+_"
                p output
                p upload
                p history
                p "+_+_+_+_+_"

                # Perform spatial query on the UTM geometry
                if output[:errors].count == 0 && output[:count] > 0
                    output[:pass] = true

                    history.update(message: "Manually Rejected #{history.rejected_tiles.count} Tiles, #{history.rejected_footprints.count} Footprints, and #{history.rejected_frame_centers.count} Frame Centers")
                    output[:message] = history.message

                    # Add the number of files uploaded
                    upload.number_uploaded = output[:count]
                    upload.save

                    # add records to polymorphic association
                    history.uploads << upload
                    # history.rejected_tiles = upload.rejected_tiles

                    # Log and send email
                    Mailbox.ship({
                        users: MailGroup.find_by(name: "Rejection").users,
                        subject: "Tiles have been rejected",
                        message: "The following Tiles have been rejected:<br/><ul>#{history.rejected_tiles.map {|rt| "<li><b>#{rt.poly_id}</b> - <i>(Flight Date: #{rt.flight_date.strftime("%m/%d/%Y")}, Flown By: #{rt.flown_by_name})</i></li>"}.join("")}</ul>"
                    })

                    # Rails.application.secrets.rejection_users.each do |user|
                    #     next if User.find_by(user).nil?
                    #     PostmasterMailer.notify(User.find_by(user), "The following Tiles have been rejected:<br/><ul>#{history.rejected_tiles.map {|rt| "<li><b>#{rt.poly_id}</b> - <i>(Flight Date: #{rt.flight_date.strftime("%m/%d/%Y")}, Flown By: #{rt.flown_by_name})</i></li>"}.join("")}</ul>".html_safe, "USDA #{Rails.application.secrets.project_year}: Tiles have been rejected - #{Time.now.strftime("%m/%d/%Y")}").deliver
                    # end
                else
                    raise Exception, "Error Occurred when attempting to Reject Tiles. Process Aborted."
                end

            rescue Exception => exception
                Rails.logger.error "Rejection Import Error: #{exception.message}"
                output[:pass] = false
                output[:errors] = [exception.message]

                # Delete the Upload and History
                upload.destroy if upload.present?
                history.destroy if history.present?

                # Delete the files
                FileUtils.rm_rf("#{path}/") if path

                raise ActiveRecord::Rollback
            end
        end

        # Return output to controller
        output

    end


    def self.reject_tiles poly_ids, flight_date, history, skip_coverage=false, message="Manual Rejection"

        output = {
            count: 0
        }

        # Start a Transaction Block
        ActiveRecord::Base.transaction(joinable: false, requires_new: true) do
            begin

                Tile.where(poly_id: poly_ids).each do |tile|

                    # get the footprint ids for future reference
                    footprint_ids = tile.footprints.where(
                        flight_date: flight_date, 
                        flown_by_id: tile.flown_by_id,
                        camera_id: tile.camera_id,
                    ).pluck(:id)

                    # Update the Easement to not be set to flight date
                    tile.easement.update(flight_date: nil)

                    # Reject the tiles
                    rejected_tile = RejectedTile.reject tile, message, skip_coverage

                    if !rejected_tile
                        # raise "Tile (#{tile.poly_id}) could not be rejected!"
                        # raise ActiveRecord::Rollback
                        raise Exception, "Tile (#{tile.poly_id}) could not be rejected!"
                    end

                    # push the easement and tiles to the history object
                    history.tiles << tile
                    history.easements << tile.easement
                    history.rejected_tiles << rejected_tile

                    p "Footprint IDs"
                    p footprint_ids

                    # Check if the footprints has any other association
                    # => If they don't then reject them (Rejecting the tile automatically removes the association)
                    Footprint.where(id: footprint_ids).each do |footprint|

                        if footprint.tiles.count == 0

                            # get the frame center before deleting the footprint
                            framecenter = footprint.frame_center

                            # Reject the Footprint
                            rejected_footprint = RejectedFootprint.reject footprint, message

                            if !rejected_footprint
                                # raise "Footprint could not be rejected!"
                                # raise ActiveRecord::Rollback
                                raise Exception, "Footprint could not be rejected!"
                            end

                            # Reject the associated Frame Center of the footprint
                            if framecenter

                                # Find the rejected frame center
                                rejected_frame_center = RejectedFrameCenter.reject framecenter, message

                                # 
                                if !rejected_frame_center
                                    raise Exception, "Frame Center #{fc.id} could not be rejected!"
                                end

                                # Add the rejected frame centers to history
                                history.rejected_frame_centers << rejected_frame_center
                            end

                            # Add rejected footprints to history
                            history.rejected_footprints << rejected_footprint
                        end
                    end

                    output[:count] += 1

                end
            rescue => exception
                Rails.logger.error "REJECTION ERROR: #{exception.message}"
                output[:pass] = false
                output[:errors] << exception.message
                raise ActiveRecord::Rollback
                return output, upload, history
            end
        end

        return output, history

    end

    # # def self.reject_and_find_coverage poly_id, flight_date, output, upload, history
    # def self.reject_and_find_coverage poly_id="6667409800CCX", flight_date="2022-07-15", footprint_flight_date="2022-08-09", footprint_flown_by_id=1, footprint_camera_id=4, footprint_plane_id=4

    #     tile = Tile.find_by(poly_id: poly_id)

    #     # Check if the footprint coverage exists
    #     footprint_coverage = Footprint.exclude_geom.where(flight_date: footprint_flight_date, flown_by_id: footprint_flown_by_id, camera_id: footprint_camera_id, plane_id: footprint_plane_id)

    #     # Reject the tile
    #     # get the footprint ids for future reference
    #     footprint_ids = tile.footprints.where(
    #         flight_date: flight_date, 
    #         flown_by_id: tile.flown_by_id,
    #         camera_id: tile.camera_id,
    #     ).pluck(:id)

    #     # Update the Easement to not be set to flight date
    #     tile.easement.update(flight_date: nil)

    #     # Reject the tiles
    #     rejected_tile = RejectedTile.reject tile

    #     if !rejected_tile
    #         # raise "Tile (#{tile.poly_id}) could not be rejected!"
    #         # raise ActiveRecord::Rollback
    #         raise Exception, "Tile (#{tile.poly_id}) could not be rejected!"
    #     end

    #     # push the easement and tiles to the history object
    #     # history.tiles << tile
    #     # history.easements << tile.easement
    #     # history.rejected_tiles << rejected_tile

    #     p "Footprint IDs"
    #     p footprint_ids

    #     # Check if the footprints has any other association
    #     # => If they don't then reject them (Rejecting the tile automatically removes the association)
    #     Footprint.where(id: footprint_ids).each do |footprint|

    #         if footprint.tiles.count == 0

    #             # get the frame center before deleting the footprint
    #             framecenter = footprint.frame_center

    #             # Reject the Footprint
    #             rejected_footprint = RejectedFootprint.reject footprint

    #             if !rejected_footprint
    #                 # raise "Footprint could not be rejected!"
    #                 # raise ActiveRecord::Rollback
    #                 raise Exception, "Footprint could not be rejected!"
    #             end

    #             # Reject the associated Frame Center of the footprint
    #             if framecenter
    #                 rejected_frame_center = RejectedFrameCenter.reject framecenter

    #                 if !rejected_frame_center
    #                     # raise "Frame Center #{fc.id} could not be rejected!"
    #                     # raise ActiveRecord::Rollback
    #                     raise Exception, "Frame Center #{fc.id} could not be rejected!"
    #                 end

    #                 # history.rejected_frame_centers << rejected_frame_center
    #             end

    #             DissolvedFootprint.find_or_create_by(name: "rejection_coverage_update").update(geom: nil)
    #             sql = "UPDATE dissolved_footprints SET geom = (SELECT ST_Multi(st_union(ST_Multi(geom::geometry))) AS the_geom from footprints where ST_IsValid(geom::geometry) AND footprints.id IN (#{footprint_coverage.pluck(:id).join(", ")})) WHERE name='rejection_coverage_update'"
    #             result = ActiveRecord::Base.connection.execute(sql)

    #             first_fooptrint = footprint_coverage.first

    #             Easement.where(id: tile.easement.id).joins("INNER JOIN dissolved_footprints ON dissolved_footprints.name='rejection_coverage_update' AND st_contains(dissolved_footprints.geom::geometry, easements.geom::geometry)").each do |easement|

    #                 easement.update(flight_date: first_fooptrint.flight_date)

    #                 easement.tiles.each do |tile|
    #                     tile.update(flight_date: first_fooptrint.flight_date, flown_by_id: first_fooptrint.flown_by_id, flown_by_name: first_fooptrint.flown_by_name, plane_name: first_fooptrint.plane_name, camera_name: first_fooptrint.camera_name, plane_id: first_fooptrint.plane_id, camera_id: first_fooptrint.camera_id, pilot: first_fooptrint.pilot_name, sensor_operator: first_fooptrint.camera_operator_name)
    #                     tile.footprints << footprints
    #                     tile.update(filename: tile.build_filename)
    #                     tile.generate_median_flight_date_time
    #                 end

    #             end

    #             # Add rejections to history
    #             # history.rejected_footprints << rejected_footprint
    #         end
    #     end


    # end

    # def self.find_potential_mistakes

    #     poly_ids = []

    #     RejectedTile.update_all(notes: nil)

    #     RejectedTile.all.each do |rt|
    #         if !rt.tile.flown && rt.rejected_footprints.count == 0
    #             rt.update(notes: "Possible Mistake")
    #             poly_ids << rt.poly_id
    #         end
    #     end

    #     p "COUNT: #{poly_ids.count}"
    #     p poly_ids

    # end


    # def self.find_covered_not_flown_easements

    #     # Iterate over rejected tiles and get easement
    #     # perform spatial query against footprints that cover it
    #     # Dissolve by Flight Date and check if Easement is covered

    #     # Start a Transaction Block
    #     ActiveRecord::Base.transaction do
    #         begin

    #         # Create a new History record
    #         history = History.new
    #         history.action_type = "Find Coverage for Rejected Easements"
    #         history.creator = User.admins.first
    #         history.save

    #         output = ""

    #         # f = File.open("/media/sf_shared/audit/easements_covered_but_not_flown.csv", "w+")

    #         # f.puts "PolyID, State, Flight Date, Strip Frames\n"

    #         easement_count = 0
    #         footprint_count = 0

    #         # rt = RejectedTile.find(88)
    #         # Easement.not_flown.all.each do |easement|
    #         # Easement.where(upload_id: Upload.last.id).each do |easement|
    #         RejectedTile.all.each do |rt|

    #             p rt.easement.poly_id
    #             next if rt.easement.flown?

    #             easement = rt.easement
            
    #             # Query against the Footprint geometry scoped based on the previous footprint id array
    #             # sql = "SELECT fp.id as fp_id, 
    #             sql = "SELECT fp.id as fp_id, 
    #                     fp.flight_date as fp_flight_date, 
    #                     fp.flown_by_id as fp_flown_by_id,
    #                     fp.camera_id as fp_camera_id,
    #                     fp.plane_id as fp_plane_id 
    #                     from easements e, footprints fp where st_intersects(e.geom, fp.geom) AND e.id = #{easement.id} AND fp.project='#{easement.project}' ORDER BY fp.flight_date DESC"
    #             results = ActiveRecord::Base.connection.execute(sql)

    #             footprints = {}

    #             results.each do |result|
    #                 # p result

    #                 if !footprints["#{result["fp_flight_date"]}_#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"] 
    #                     footprints["#{result["fp_flight_date"]}_#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"] = {
    #                         flight_date: result["fp_flight_date"],
    #                         fp_flown_by_id: result["fp_flown_by_id"],
    #                         fp_camera_id: result["fp_camera_id"],
    #                         fp_plane_id: result["fp_plane_id"],
    #                         ids: [result["fp_id"]]
    #                     }
    #                 else 
    #                     footprints["#{result["fp_flight_date"]}_#{result["fp_flown_by_id"]}_#{result["fp_camera_id"]}_#{result["fp_plane_id"]}"][:ids] << result["fp_id"]
    #                 end

    #             end

    #             # pp footprints

    #             # Begin dissolve and iteration

    #             footprints.each do |key, obj|
    #                 DissolvedFootprint.footprints obj[:ids], easement.project

    #                 sql = "SELECT ST_Contains(df.geom::geometry, e.geom::geometry) FROM dissolved_footprints df, easements e WHERE df.name = 'footprints'  AND e.id = #{easement.id}"
    #                 results = ActiveRecord::Base.connection.execute(sql)

    #                 # p results[0]

    #                 if results[0]["st_contains"] == true
    #                     # p "UPDATE"

    #                     footprints = Footprint.exclude_geom.where(id: obj[:ids])

    #                     first_fp = footprints.first

    #                     # f.puts "#{easement.poly_id}, #{first_fp.state_name}, #{obj[:flight_date]}, '[#{footprints.pluck(:strip_frame).join(", ")}]' \n"
    #                     # output += "PolyID: #{easement.poly_id} ; Flight Date: #{obj[:flight_date]} - [#{obj[:ids].join(", ")}] \n"

    #                     at_date = first_fp.frame_center ? first_fp.frame_center.created_at : nil

    #                     p "Updating: #{obj[:flight_date]} - #{obj[:ids].join(", ")}"

    #                     # Find and updat the tile
    #                     tile = easement.tiles.first
    #                     tile.update(flight_date: obj[:flight_date], at_start_date: at_date, at_done_date: at_date)
    #                     tile.easement.update(flight_date: obj[:flight_date])
    #                     tile.footprints << footprints
    #                     tile.update(filename: tile.build_filename)
    #                     tile.generate_median_flight_date_time

    #                     # find tile that was flown by same footprints and copy values
    #                     tile.update(flown_by_id: first_fp.flown_by_id, flown_by_name: first_fp.flown_by_name, plane_name: first_fp.plane_name, camera_name: first_fp.camera_name, plane_id: first_fp.plane_id, camera_id: first_fp.camera_id)

    #                     p "-----------"
    #                     easement_count += 1
    #                     footprint_count += obj[:ids].size
    #                     p "-----------"

    #                     history.easements << easement
    #                     history.tiles << tile

    #                     break

    #                 end

    #             end
    #         end

    #         history.update(
    #             message: "Updated #{easement_count} Easements and associated #{footprint_count} Footprints"
    #         )

    #         # p output
    #         # f.close
    #     rescue Exception => exception
    #         Rails.logger.error "Rejection find_covered_not_flown_easements: #{exception.message}"
    #         error_message = exception.message

    #         # # Delete the Upload and History
    #         # upload.destroy if upload.present?
    #         # history.destroy if history.present?

    #         # Delete the files
    #         FileUtils.rm_rf("#{path}/") if path

    #         # Update the process
    #         process_success = false

    #         raise ActiveRecord::Rollback
    #     end

    # end

    private

    # def self.import_txt output, upload, path, params, history
    #     txt = Dir.glob("#{path}/*.txt").first

    #     if txt.empty?
    #         output[:errors] << "Could not find text file to upload"
    #         FileUtils.rm_rf(path)
    #         return output, upload
    #     end

    #     flight_date = params[:flight_date]
    #     poly_ids = []

    #     File.open(txt, "r") do |f|
    #         f.each_line do |line|

    #             # Get the tile, only should be one
    #             tile = Tile.flown.asi_accepted.find_by(
    #                 poly_id: line.strip, 
    #                 flight_date: flight_date
    #             )

    #             # If present then push the Tile id to an array
    #             if tile.present?
    #                 poly_ids << tile.poly_id
    #             end
    #         end
    #     end

    #     Rejection.reject_tiles poly_ids, flight_date, output, upload, history

    # end

    # def self.reject_footprints_and_frame_centers_by_tile tile, flight_date

    #     # Find all footprints that intersect the tile
    #     sql = "SELECT footprints.id FROM footprints, tiles WHERE ST_Intersects(tiles.geom::geometry, footprints.geom::geometry) AND tiles.id = #{tile.id} and footprints.flight_date = '#{Date.parse(flight_date).strftime("%Y-%m-%d")}';"
    #     fp_result = ActiveRecord::Base.connection.execute(sql)

    #     # Iterate the footprints
    #     fp_result.each do |fp_record|
    #         # Update each footprint that 
    #         Footprint.find(fp_record["id"]).update(rejected_date: Time.now)

    #         sql = "SELECT frame_centers.id FROM frame_centers, footprints WHERE ST_Intersects(footprints.geom::geometry, frame_centers.geom::geometry) AND footprints.id = #{fp_record["id"]} and DATE(frame_centers.flight_date) = '#{Date.parse(flight_date).strftime("%Y-%m-%d")}';"
    #         fc_result = ActiveRecord::Base.connection.execute(sql)

    #         # Iterate the footprints
    #         fc_result.each do |fc_record|
    #             fc = FrameCenter.find(fc_record["id"])

    #             # Reject the Frame Center unless it is already rejected
    #             fc.update(rejected_date: Time.now, notes: "Automatic Rejection by the Rejection Tool") unless fc.rejected?
    #         end
    #     end

    #     # Find and update all tiles that have rejected frame centers covering them
    #     FrameCenter.find_tiles_of_rejected_frame_centers

    # end

end
