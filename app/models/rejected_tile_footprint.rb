class RejectedTileFootprint < ApplicationRecord

    # Associations
    belongs_to :tile
    # belongs_to :camera
    # belongs_to :flown_by, class_name: 'Company'
    belongs_to :rejected_tile, optional: true
    belongs_to :rejected_footprint, optional: true

end
