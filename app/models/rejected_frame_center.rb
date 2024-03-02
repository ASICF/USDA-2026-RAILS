class RejectedFrameCenter < ApplicationRecord

    # Associations
    belongs_to :county, optional: true
    belongs_to :state, optional: true
    belongs_to :utm, optional: true
    belongs_to :upload
    belongs_to :camera
    belongs_to :plane
    belongs_to :rejected_footprint, optional: true
    belongs_to :flown_by, class_name: 'Company'
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs

    def self.reject frame_center, reason="Auto Rejection"

        # create a copy of the tile to store in the Rejected Tile
        record = frame_center.as_json
        p record

        return if frame_center.nil?

        record.delete("id")
        record.delete("review_desc")
        # record.delete("footprint_id")

        # Find the rejected footprint
        rejected_footprint = RejectedFootprint.find_by(original_id: frame_center.footprint_id)

        p "frame center rejected_footprint"
        p rejected_footprint

        if rejected_footprint.nil?
            return false
        end

        # Create the rejected tile
        rejected_frame_center = RejectedFrameCenter.new(record)
        rejected_frame_center.update(
            original_id: frame_center.id,
            rejected_date: Time.now,
            rejection_type: reason,
            rejected_footprint_id: rejected_footprint.id
        )

        if !rejected_frame_center.save
            p rejected_frame_center.errors.full_messages.to_sentence
            return false
        end

        # Delete the original frame center
        frame_center.destroy

        return rejected_frame_center
    end

    def unreject footprint

        # Check if the Frame Center already exists or not
        # Match based on the strip_frame, flight date, flown by, camera, latitude, and longitude
        existing_frame_center = FrameCenter.find_by(
            strip_frame: self.strip_frame,
            flight_date: self.flight_date, 
            flown_by_id: self.flown_by_id, 
            camera_id: self.camera_id,
            latitude: self.latitude,
            longitude: self.longitude
        )
        if existing_frame_center.present?
            return existing_frame_center
        end

        # #get the rejected tile as json
        rejected_frame_center = self.as_json
        rejected_frame_center["id"] = self.original_id
        rejected_frame_center.delete("rejected_date")
        rejected_frame_center.delete("rejection_type")
        rejected_frame_center.delete("original_id")
        rejected_frame_center.delete("rejected_footprint_id")

        frame_center = FrameCenter.new(rejected_frame_center)
        frame_center.footprint = footprint

        if !frame_center.save
            p frame_center.errors.full_messages.to_sentence
            return false
        end

        frame_center

    end

    def self.find_rejected_tiles

        rejected_tiles = []

        RejectedFrameCenter.includes(rejected_footprint: [:rejected_tiles]).where(sun_angle_error: true).each do |rfc|

            rfc.rejected_footprint.rejected_tiles.each do |rt|

                # add it to the list if the current tile is not flown
                rejected_tiles << rt.poly_id if rt.tile.flight_date.nil?

            end

        end

        p rejected_tiles.uniq
        p rejected_tiles.uniq.count

    end

end
