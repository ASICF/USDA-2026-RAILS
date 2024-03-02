class ImageryPath < ApplicationRecord

    # Assocations
    belongs_to :pathable, polymorphic: true
    belongs_to :user

    # Scopes
    scope :sl, -> { where(project: "SL") }
    scope :naip, -> { where(project: "NAIP") }

end
