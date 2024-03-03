class ContractAward < ApplicationRecord

    # => Status based Scopes
    scope :sl,  -> { where(project: "SL") }
    scope :nri, -> { where(project: "NRI") }
    scope :naip, -> { where(project: "NAIP") }

    # Associations
    belongs_to :state
    has_many :easements
    has_many :tiles
    has_many :rejected_tiles

end
