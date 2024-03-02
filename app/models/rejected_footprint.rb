class RejectedFootprint < ApplicationRecord

    # Associations
    belongs_to :upload
    belongs_to :plane
    belongs_to :camera
    belongs_to :state, optional: true
    belongs_to :county, optional: true
    belongs_to :utm, optional: true
    belongs_to :vector_metadatum, optional: true
    belongs_to :flown_by, class_name: 'Company', optional: true
    has_one :rejected_frame_center
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs
    has_many :tile_footprints
    has_many :tiles, through: :tile_footprints
    has_many :rejected_tile_footprints
    has_many :rejected_tiles, through: :rejected_tile_footprints

    # Scopes
    scope :sl, -> { where(project: "SL") }
    scope :naip, -> { where(project: "NAIP") }

    def self.reject footprint, type="ASI Reject"

        # Start a Transaction Block
        ActiveRecord::Base.transaction(joinable: false, requires_new: true) do
            begin

            # create a copy of the tile to store in the Rejected Tile
            record = footprint.as_json
            record.delete("id")
            record.delete("review_desc")
            # record.delete("centroid_latitude")
            # record.delete("centroid_longitude")
            record["original_id"] = footprint.id
            record["rejected_date"] = Time.now
            record["rejection_type"] = type

            # Create the Rejected Footprint
            rejected_footprint = RejectedFootprint.new(record)

            if !rejected_footprint.save
                Rails.logger.error "Rejected Footprint Error"
                Rails.logger.error rejected_footprint.errors.full_messages.to_sentence

                raise Exception, rejected_footprint.errors.full_messages.to_sentence
            end

            # Update any existing RTFs
            RejectedTileFootprint.where(
                flight_date: footprint.flight_date,
                strip_frame: footprint.strip_frame,
                original_footprint_id: footprint.id,
                camera_id: footprint.camera_id,
                flown_by_id: footprint.flown_by_id,
                rejected_footprint_id: nil
            ).update_all(rejected_footprint_id: rejected_footprint.id)

            # Iterate the tile's tile_footprint
            # Check if the rtf exists
            # if not then create it
            footprint.tiles.each do |tile|

                # See if the the rtf exists or not (would have been created by the footprint)
                if RejectedTileFootprint.find_by(
                    flight_date: footprint.flight_date,
                    strip_frame: footprint.strip_frame,
                    tile_id: tile.id, 
                    camera_id: footprint.camera_id,
                    flown_by_id: footprint.flown_by_id,
                    original_footprint_id: footprint.id
                ).nil?
                    # p "footprint 2"
                    # p footprint
                    rejected_footprint.rejected_tile_footprints.create(
                        flight_date: footprint.flight_date,
                        strip_frame: footprint.strip_frame,
                        tile_id: tile.id, 
                        camera_id: footprint.camera_id,
                        flown_by_id: footprint.flown_by_id,
                        original_footprint_id: footprint.id,
                        rejected_tile_id: nil
                    )
                end
            end

            # Remove the footprint from the associated tile
            footprint.tiles = []

            # Delete the original Footprint
            footprint.destroy

            return rejected_footprint

            rescue => exception
                Rails.logger.error "Rejected Footprint Error: #{exception.message}"
                raise ActiveRecord::Rollback
            end
        end

    end

    def unreject
        
        # Check if the Footprint already exists or not
        # Match based on the strip frame, flight date, flown by, and camera
        existing_footprint = Footprint.find_by(
            strip_frame: self.strip_frame,
            flight_date: self.flight_date, 
            flown_by_id: self.flown_by_id, 
            camera_id: self.camera_id
        )
        if existing_footprint.present?
            return existing_footprint
        end

        # #get the rejected tile as json
        footprint = self.as_json
        footprint["id"] = self.original_id

        # # Remove unnecessary fields
        footprint.delete("id")
        footprint.delete("rejected_date")
        footprint.delete("rejection_type")
        footprint.delete("original_id")

        Footprint.create(footprint)
    end

    def self.find_missing_footprints

        # match = []

        # Tile.flown.includes(:footprints).each do |tile|
        #     tile.footprints.each do |fp|
        #         match << tile if fp.flight_date != tile.flight_date
        #     end
        # end

        # p match.count
        rejected_footprints = []

        RejectedTile.includes(:rejected_footprints).where(rejected_footprints: {id: nil}).each do |rt|

            p "--------------"
            p rt
            p "++++++"

            # Get the tile
            tile = rt.tile
            easement = tile.easement

            # check the easement to see if it's been reflown
            # Query against the Footprint geometry scoped based on the previous footprint id array
            sql = "SELECT DISTINCT fp.id as footprint_id from easements e, footprints fp where st_intersects(e.geom, fp.geom) 
                AND e.id = #{easement.id} AND fp.camera_id=#{rt.camera_id} AND fp.flown_by_id=#{rt.flown_by_id} 
                AND fp.plane_id=#{rt.plane_id} AND fp.project='#{rt.project}' AND fp.flight_date = '#{rt.flight_date.strftime("%F")}'"

            footprint_results = ActiveRecord::Base.connection.execute(sql)

            footprint_results.each do |fp_result|
                p fp_result

                # Check if the footprint has any other associations to other easements
                fp = Footprint.find(fp_result["footprint_id"])

                # Check if the footprint has any other associated easements
                sql = "SELECT e.id as footprint_id from easements e, footprints fp where st_intersects(e.geom, fp.geom) 
                    AND e.id <> #{easement.id} AND fp.id = #{fp_result["footprint_id"]} AND e.flight_date = '#{rt.flight_date.strftime("%F")}'"
                easement_results = ActiveRecord::Base.connection.execute(sql)

                # If there are no other easements and no associations then reject it
                if easement_results.count == 0 && fp.tiles.count == 0
                    rejected_footprints << fp.id
                    rejected_footprint = RejectedFootprint.reject fp
                end

            end

        end

        p rejected_footprints.uniq
        p "done"

    end

    def self.unreject_these_doqq_footprints
        
        strip_frames = ["1109_2249", "1109_2248", "1109_2247", "1109_2244", "1109_2243", "1108_2254", "1108_2253", "1108_2252", "1108_2251", "1108_2250"]
        flight_date = "2022-09-02"
        upload = Upload.find(887)
        
        vm = nil
        flight_date = Date.parse(flight_date)
        provisional_due_date = 5.business_days.after(flight_date)
        footprints = []

        RejectedFootprint.where(strip_frame: strip_frames, project: "NAIP", flight_date: flight_date).each do |rfp|
            # Unreject the footprint
            footprint = rfp.unreject
            footprints << footprint

            if rfp.rejected_frame_center.present?
        
                # Unreject the rejected footprint's rejected frame center
                frame_center = rfp.rejected_frame_center.unreject footprint
                
                frame_center.update(sun_angle_error: false, notes: "Unrejected because production used imagery for final delivery")
            end

            vm = VectorMetadatum.find_or_create_by(
                project: "NAIP", 
                flight_date: flight_date,
                service_name: "NJ_PROVISIONAL_4B_#{flight_date.strftime("%Y%m%d")}",
                state_name: "New Jersey",
                provisional_due_date: provisional_due_date,
                state_id: 11
            )
        end
        
        # Dissolve the footprints 
        DissolvedFootprint.dissolve_by_flight_date flight_date.strftime("%F"), "NAIP"

        # find and update the doqqs
        Footprint.update_doqqs upload, upload.history, "NAIP", vm

    end

end
