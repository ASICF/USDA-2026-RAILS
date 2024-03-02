class Job < ApplicationRecord

    # Associations
    belongs_to :upload, optional: true
    belongs_to :creator, class_name: 'User'

    # Scopes
    scope :active, -> { where(active: true) }
    scope :success, -> { where(active: false, success: true) }
    scope :failed, -> { where(active: false, success: false) }

end
