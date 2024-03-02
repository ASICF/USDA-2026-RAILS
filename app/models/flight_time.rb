class FlightTime < ApplicationRecord

    # Associations
    belongs_to :tile

    # # Validations
    validates :flight_date, :start_date, :end_date, presence: true
    validates :flight_date, uniqueness: { scope: :tile_id }

end
