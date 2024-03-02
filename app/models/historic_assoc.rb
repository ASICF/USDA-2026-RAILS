class HistoricAssoc < ApplicationRecord

    # Associations
    belongs_to :history
    belongs_to :historicable, polymorphic: true

    # Callbacks
    after_create :update_search_field

    # Used for updating the Search fields for the timeline
    def update_search_field
        # p "------------"
        # p "HistoryAssoc: Creating search_term field"
        # p self
        # p self.id
        # # p self.historicable
        # p "------------"

        if self.historicable.nil?
            return
        end

        case historicable_type
        when "AirborneDigitalSensor"
            self.search_terms = "#{self.historicable.line_id}"
        when "RejectedAirborneDigitalSensor"
            self.search_terms = "#{self.historicable.line_id}"
        when "Camera"
            self.search_terms = "#{self.historicable.name} #{self.historicable.model} #{self.historicable.serial_number} #{self.historicable.manufacturer} #{self.historicable.company.name}"
        when "Company"
            self.search_terms = "#{self.historicable.name} #{self.historicable.alias}"
        when "Easement"
            self.search_terms = "#{self.historicable.poly_id}"
        when "FrameCenter"
            str = ""
            self.historicable.upload.history.tiles.each {|tile| str += "#{tile.poly_id} "}

            message_arr = self.history.message.split('"')
            str += message_arr[1] if message_arr.size == 2
            
            self.search_terms = "#{self.historicable.strip_frame} #{self.historicable.flown_by_name} #{str}"
        when "RejectedFrameCenter"
            self.search_terms = "#{self.historicable.strip_frame} #{self.historicable.flown_by_name}"
        when "PackingSlip"
            self.search_terms = "#{self.historicable.name}"
        when "Plane"
            self.search_terms = "#{self.historicable.name} #{self.historicable.model} #{self.historicable.company.name}"
        when "Footprint"
            self.search_terms = "#{self.historicable.strip_frame} #{self.historicable.original_strip_frame} #{self.historicable.flown_by_name} #{self.historicable.camera_operator_name} #{self.historicable.pilot_name} #{self.historicable.camera_name} #{self.historicable.plane_name}"
        when "RejectedFootprint"
            self.search_terms = "#{self.historicable.strip_frame} #{self.historicable.original_strip_frame} #{self.historicable.flown_by_name} #{self.historicable.camera_operator_name} #{self.historicable.pilot_name} #{self.historicable.camera_name} #{self.historicable.plane_name}"
        when "Tile"
            self.search_terms = "#{self.historicable.poly_id} #{self.historicable.filename} #{self.historicable.line_id} #{self.historicable.psn} #{self.historicable.county_name}  #{self.historicable.pilot}  #{self.historicable.sensor_operator} #{self.historicable.camera_name} #{self.historicable.plane_name}"
        when "RejectedTile"
            self.search_terms = "#{self.historicable.poly_id} #{self.historicable.filename} #{self.historicable.line_id} #{self.historicable.psn} #{self.historicable.county_name}  #{self.historicable.pilot}  #{self.historicable.sensor_operator} #{self.historicable.camera_name} #{self.historicable.plane_name}"
        when "User"
            self.search_terms = "#{self.historicable.first_name} #{self.historicable.last_name}"
        when "Doqq"
            self.search_terms = "#{self.historicable.qq_apfo_name} #{self.historicable.psn} #{self.historicable.project_no} #{self.historicable.filename}"
        when "RejectedDoqq"
            self.search_terms = "#{self.historicable.qq_apfo_name}"
        when "PhotoIndex"
            self.search_terms = "#{self.historicable.strip_frame}"
        else
            p "not found: #{historicable_type}"
        end

        self.save
    end
end
