class TimeZone < ApplicationRecord

    # Associations
    has_many :easements

    # Validation
    validates :name, presence: true 

end
