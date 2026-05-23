class Loadout < ApplicationRecord

    # Associations
    belongs_to :camera
    belongs_to :plane

    # validations
    validates :name, presence: true, uniqueness: { case_sensitive: false }

end
