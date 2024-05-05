class Invoice < ApplicationRecord

    # Validation
    validates :number, :invoice_date, :project, :amount, presence: true

    # Associations
    has_many :packing_slips

    # Callbacks
    after_save :calculate_total

    def calculate_total

        ps_obj = {}
        total_acres = 0
        total_price = 0.0        

        # return distinct production and flight rates using the packing slip ids
        ps_ids = packing_slips.pluck(:id)
        state_ids = packing_slips.order(:state_abv).pluck(:state_id)

        state_ids.each do |state_id|

            state = State.find(state_id)
            ps_obj[state.abv] = []

            # get unique tiles with 
            Tile.where(state_id: state_id, packing_slip_id: ps_ids).pluck(:flown_by_id).uniq.each do |flown_by_id|

                # get the acres
                acres = Tile.where(state_id: state_id, packing_slip_id: ps_ids, flown_by_id: flown_by_id).sum(:easements_acres).to_f.round(0)

                # get the first tile
                tile = Tile.where(state_id: state_id, packing_slip_id: ps_ids, flown_by_id: flown_by_id).first

                # get the rates
                rate = (ContractRate.find(tile.production_rate_id).cost.to_f + ContractRate.find(tile.flight_rate_id).cost.to_f).round(2)

                # get the price
                price = (acres * rate).round(2)

                ps_obj[state.abv] << {
                    acres: acres,
                    rate: rate,
                    price: price
                }


            end

        end

        pp ps_obj

        ps_obj.each do |state, array|
            array.each do |item|
                total_acres += item[:acres]
                total_price += item[:price]
            end
        end

        # # find grouped values across the packing slip, flight rate and production rate
        # grouped = Tile.flown.where(packing_slip_id: ps_ids).select(:packing_slip_id, :flight_rate_id, :production_rate_id).distinct

        # # pp grouped

        # # # Iterate the groups and calculate the totals
        # grouped.each do |group|
        #     acres = Tile.select(:easements_acres).where(
        #         state_id: group.state_id,
        #         flight_rate_id: group.flight_rate_id,
        #         production_rate_id: group.production_rate_id,
        #         packing_slip_id: ps_ids
        #     ).sum(:easements_acres).to_f.round(0)

        #     rate = (ContractRate.find(group.production_rate_id).cost.to_f + ContractRate.find(group.flight_rate_id).cost.to_f).round(2)

        #     total_acres += acres
        #     total_price += acres * rate.to_f

        #     ps_obj[group.packing_slip_id.to_s] = {
        #         state: PackingSlip.find(group.packing_slip_id).tiles.first.state_name,
        #         acres: acres,
        #         rate: rate.to_f,
        #         price: acres * rate.to_f
        #     }
        # end

        # p ps_obj

        # ps_obj.each do |ps, obj|
        #     p ps
        #     p obj
        #     p "------------"
        # end

        p "-----------"
        p total_acres
        p total_price
        p "-----------"

        # iterate the states of the packing slip
        # Sum the acres and round to 0
        # round the PPA

        # states = Tile.select(:state_id).where(packing_slip_id: ps_ids).pluck(:state_id).uniq

        # states.each do |state_id|
        #     Tile.where(packing_slip_id: ps_ids, state_id: state_id)
        # end


        # # Iterate Packing Slips (should be scoped by state)
        # packing_slips.each do |ps|

        #     obj = {}

        #     ps.tiles.includes(:flight_rate, :production_rate).each do |tile|

        #         # rates = ContractRate.find_rates self.flight_date, self.flown_by, self.state, self.project
        #         amount = tile.flight_rate.cost + tile.production_rate.cost

        #         if obj[amount.to_s]
        #             p "Found state and amount"
        #             pp obj[amount.to_s][:acres]
        #             obj[amount.to_s][:acres] += tile.easements_acres.to_f
        #         else
        #             p "Found state but not amount"
        #             obj[amount.to_s] = {
        #                 acres: tile.easements_acres.to_f,
        #                 ppa: amount.to_f,
        #                 rounded_acres: 0.0,
        #                 amount: 0.0
        #             }
        #         end

        #     end

        #     # find 

        #     # iterate the packing slip tiles based on unique flight and production rate ids
        #     # pull the rates and sum the easements acres totals



        #     p "-----------"
        #     pp obj

        #     # # Sum and round the acres to nearest integer
        #     # total_acres = ps.tiles.sum(:easements_acres).round(0)

        #     # # Get the Unit price
        #     # # needs to be 
        #     # ppa = 
        #     p "done"

        # end

        p "done"

    end


    def self.assign_psns

        # invoice_15167 = ["20240425_IL", "20240425_LA", "20240425_MN", "20240425_OH"]

        # invoice = Invoice.find_or_create_by!(
        #     number: "15167",
        #     invoice_date: "2024-04-26",
        #     project: "SL",
        #     amount: 0.0
        # )

        # PackingSlip.where(name: invoice_15167).each do |psn|
        #     psn.update(
        #         invoice_id: invoice.id
        #     )
        # end

        # invoice_15166 = ["20240404_WV", "20240405_TN", "20240405_KY", ]

        # invoice = Invoice.find_or_create_by!(
        #     number: "15166",
        #     invoice_date: "2024-04-10",
        #     project: "SL",
        #     amount: 0.0
        # )

        # PackingSlip.where(name: invoice_15166).each do |psn|
        #     psn.update(
        #         invoice_id: invoice.id
        #     )
        # end

        invoice_15165 = ["20240329_AL", "20240329_KY", "20240401_IN", "20240401_TN", "20240401_WV", "20240404_WV", "20240405_AL", "20240405_KY", "20240405_NC", "20240405_TN", "20240406_VA", "20240407_LA", "20240408_GA"]

        invoice = Invoice.find_or_create_by!(
            number: "15165",
            invoice_date: "2024-04-10",
            project: "SL",
            amount: 0.0
        )

        PackingSlip.where(name: invoice_15165).each do |psn|
            psn.update(
                invoice_id: invoice.id
            )
        end

    end

end
