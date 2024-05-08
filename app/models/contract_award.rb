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

    def self.update_ppa

        # divide by the contract award amount
        # round to 2 decimals

        ContractAward.all.each do |ca|

            # sum the acres of the tiles
            acres = ca.tiles.sum(:easements_acres)

            # divide by the contract award amount
            ppa = ca.amount / acres.round(0)

            # compare against the contract rate
            flight_rate = ContractRate.find_by(company_id: 1, state_id: ca.state_id, phase: "100").cost
            production_rate = ContractRate.find_by(company_id: 1, state_id: ca.state_id, phase: "300").cost

            # add the existing rate together for comparison
            rate = flight_rate + production_rate

            p "--------"
            p ca.state.name
            p acres.to_f
            p ppa.to_f.round(2)
            p rate.round(2).to_f
            p "--------"

            if ppa.to_f.round(2) === rate.round(2).to_f
                ca.update(ppa: ppa.round(2))
            else
                p "DOES NOT MATCH"
            end

        end

    end

end
