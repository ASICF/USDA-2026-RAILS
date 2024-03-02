class Utm < ApplicationRecord
    include Concerns::Archive

    # Associations
    has_many :easements
    has_many :tiles
    has_many :footprints
    has_many :frame_centers
    has_many :doqqs
    has_many :rejected_tiles

    # Scope
    scope :exclude_geom, -> { select( Utm.attribute_names - ['geom'] ) }

    # Returns all the active records
    def self.active
        Easement.all.pluck(:utm_id).uniq.map {|u| Utm.find(u) }
    end

    # Retursn the active record zone numbers
    def self.active_zones
        Easement.all.pluck(:utm_id).uniq.map {|u| Utm.find(u).zone }
    end

end