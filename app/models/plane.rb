class Plane < ApplicationRecord
    include Concerns::Archive

    # Associations
    belongs_to :company
    has_many :easements
    has_many :tiles
    has_many :doqqs
    has_many :rejected_tiles
    has_many :footprints
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs

    # Validations
    validates :name, :model, presence: true

end