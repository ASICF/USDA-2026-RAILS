class ContractAward < ApplicationRecord

    # Associations
    belongs_to :state
    has_many :easements
    has_many :tiles
    has_many :rejected_tiles

end
