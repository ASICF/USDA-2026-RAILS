class Loadout < ApplicationRecord

    # constants
    ALLOWED_NAMES = ['Underscore', 'No Underscore'].freeze

    # Associations
    belongs_to :camera
    belongs_to :plane

    # validations
    validates :name, 
            presence: true,
            inclusion: { in: ALLOWED_NAMES },
            uniqueness: true

end
