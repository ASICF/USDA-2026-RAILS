class Invoice < ApplicationRecord

    # Validation
    validates :number, :invoice_date, :project, :amount, presence: true
    validates :number, uniqueness: true

    # Associations
    has_many :packing_slips

    # Callbacks
    # after_create :calculate_total

    def self.build project, date_from, date_to, state_id, export=false
        # Invoice.build "SL", "2022-04-01", "2022-05-01"
        p "STATE_ID: #{state_id}"

        date_from = Time.parse(date_from).utc.beginning_of_day
        date_to = Time.parse(date_to).utc.end_of_day

        response = nil

        # Get the state
        state = State.find_by(id: state_id)

        if project == "SL" || project == "NRI"
            response = Invoice.build_nrisl project, date_from, date_to, state
        elsif project == "NAIP"
            response = Invoice.build_naip date_from, date_to, state
        end
        
        if export && response[:state]

            CSV.generate(headers: true) do |csv|

                if project == "SL" || project == "NRI"
                    # csv << ["State", "County", "FIPS", "Easements", "Acres", "USDA Unit Price", "Packing Slip", "Date Shipped", "Acquisition Price", "Orthos Price", "Total Price"]
                    csv << ["State", "County", "FIPS", "Shipped Easements", "Total Easements", "Shipped Acres", "Total Acres", "USDA Unit Price", "Packing Slip", "Date Shipped", "Total Price"]
                else
                    csv << ["State", "FIPS", "DOQQs", "Square Miles", "File Name", "Date Shipped"]
                end

                response[:result].each do |key, array|
                    puts "#{key}-----"

                    array.each do |record|
                        if project == "SL" || project == "NRI"
                            csv << [
                                record[:state_name],
                                record[:county_name],
                                record[:fips],
                                record[:count],
                                record[:total_count],
                                record[:acres],
                                record[:total_acres],
                                record[:unit_price],
                                # record[:sub_unit_price],
                                record[:psn_name],
                                record[:date_shipped],
                                # record[:acquisition_price],
                                # record[:orthos_price],
                                record[:total_price].round(2),
                            ]
                        else
                            csv << [
                                record[:state_name],
                                record[:fips],
                                record[:count],
                                record[:acres],
                                record[:psn_name],
                                record[:date_shipped],
                            ]
                        end
                    end
                end

            end               

        else
            return response
        end

    end

    def self.build_nrisl project, date_from, date_to, state
        # get the state and count with total easements shipped
        p "build #{project}"

        # result = []
        result = {}

        begin

            # get the state
            # => Exlcude Invoiced Packing Slips
            obj = {project: project, shipped_date: date_from..date_to, invoice_id: nil}
            obj[:tiles] = {state_id: state.id} if !state.nil?

            # Get the packing slips that were shipped during period
            psn_ids = PackingSlip.includes(:tiles).select(:id).where(obj).pluck(:id)

            p psn_ids

            obj = {packing_slip_id: psn_ids}
            obj[:state_id] = state.id if !state.nil?

            Tile.shipped.where(obj).order([:state_name, :county_name]).each do |tile|

                # Create the state
                result[tile.state_name.to_sym] = [] if result[tile.state_name.to_sym].nil?

                state_array = result[tile.state_name.to_sym]

                # check if the value exists in the array
                match = state_array.find {|a| a[:state_name] == tile.state_name && a[:county_name] == tile.county_name}

                # p match

                if match

                    # sub_unit_price = tile.flight_rate.sub_cost.to_f + tile.production_rate.sub_cost.to_f

                    match[:count] += 1
                    match[:acres] += tile.easements_acres.to_f
                    # match[:acquisition_price] += tile.flight_amount.to_f
                    # match[:orthos_price] += tile.production_amount.to_f
                    # match[:total_price] += tile.total_amount.to_f
                    # match[:sub_unit_price] |= [sub_unit_price] if sub_unit_price > 0
                    # match[:sub_acquisition_price] += tile.sub_flight_cost.to_f
                    # match[:sub_orthos_price] += tile.sub_production_cost.to_f
                    # match[:sub_total_price] += tile.sub_total_cost.to_f
                else
                    packing_slip = tile.packing_slip

                    # sub_unit_price = tile.flight_rate.sub_cost.to_f + tile.production_rate.sub_cost.to_f

                    state_array << {
                        state_name: tile.state_name,
                        fips: tile.county.full_fips,
                        county_name: tile.county_name,
                        count: 1,
                        acres: tile.easements_acres.to_f,
                        psn_name: "#{packing_slip.name}.pdf",
                        psn_id: packing_slip.id,
                        unit_price: tile.easements_acres.round(2) * tile.contract_award.ppa,

                        # total_count: tile.county.tiles.where(project: project).count,
                        # total_acres: tile.county.tiles.where(project: project).sum(:easements_acres).to_f,
                        # unit_price: tile.flight_rate.cost.to_f + tile.production_rate.cost.to_f,
                        # # sub_unit_price: sub_unit_price > 0 ? [sub_unit_price] : [],
                        # date_shipped: packing_slip.shipped_date.strftime("%m/%d/%Y"),
                        # acquisition_price: tile.flight_amount.to_f,
                        # orthos_price: tile.production_amount.to_f,
                        # total_price: tile.total_amount.to_f,
                        # # sub_acquisition_price: tile.sub_flight_cost.to_f,
                        # # sub_orthos_price: tile.sub_production_cost.to_f,
                        # # sub_total_price: tile.sub_total_cost.to_f,
                    }
                end

            end

            # Calculate the previous delivered
            state_obj = {packing_slips: {project: project}}
            state_obj[:id] = state.id if !state.nil?

            totals = {}

            # get the states and find any packing slips that are not in the current psn_ids
            State.includes(packing_slips: [:tiles]).where(state_obj).each do |state|

                ppa = state.contract_awards.where(project: project).first.ppa

                obj = {
                    previously_delivered: {
                        easements: 0,
                        acres: 0.0
                    },
                    previously_billed: {
                        easements: 0,
                        acres: 0.0,
                        ppa: ppa,
                        total: 0.0
                    },
                    total_delivery: {
                        easements: 0,
                        acres: 0.0
                    },
                    total_billing: {
                        easements: 0,
                        acres: 0.0,
                        ppa: ppa,
                        total: 0.0
                    },
                    this_billing: {
                        easements: 0,
                        acres: 0.0,
                        ppa: ppa,
                        total: 0.0
                    }
                }

                # Previously delivered
                # => get the packing slips that were delivered for the state before the date_from variable
                # ==> Total, Acres
                state.packing_slips.where(project: project).where("shipped_date < ?", date_from).each do |ps|
                    obj[:previously_delivered][:easements] += ps.tiles.count
                    obj[:previously_delivered][:acres] += ps.tiles.sum(:easements_acres)
                end

                # Previously billed
                # => get the packing slips that were delivered for the state before the date_from variable that have an invoice
                # ==> Total, Acres, contract amount, total
                invoice_ids = Invoice.where(packing_slips: {state_id: state.id}).where("invoice_date < ?", date_from)
                state.packing_slips.includes(:tiles).where(invoice_id: invoice_ids).each do |ps|
                    obj[:previously_billed][:easements] += ps.tiles.count
                    obj[:previously_billed][:acres] += ps.tiles.sum(:easements_acres)
                end

                # calculate the total billed
                obj[:previously_billed][:total] = obj[:previously_billed][:acres].round(0) * ppa


                # Total Delivery
                # => Sum of all tiles and acres
                obj[:total_delivery][:easements] = state.tiles.shipped.count
                obj[:total_delivery][:acres] = state.tiles.shipped.sum(:easements_acres)

                # Total Billing
                # invoices of the state
                # => Rounded Acres, PPA, Total
                tiles = state.tiles.shipped
                obj[:total_billing][:easements] = tiles.count
                obj[:total_billing][:acres] = tiles.sum(:easements_acres).round(0)
                obj[:total_billing][:total] = obj[:total_billing][:acres] * ppa

                # This Billing
                # calcualte using the psn_ids

                # check if the packing slip
                # tiles = state.tiles.where.not(packing_slip_id: psn_ids)
                tiles = state.tiles.shipped.where(packing_slip_id: psn_ids)
                obj[:this_billing][:easements] = tiles.count
                obj[:this_billing][:acres] = tiles.sum(:easements_acres).round(0)
                obj[:this_billing][:total] = obj[:this_billing][:acres] * ppa


                p " ------------- "
                pp obj
                p " ------------- "

                totals[state.name] = obj

            end


            return {
                state: true,
                result: result,
                totals: totals 
            }
          
        rescue StandardError => exception
            p "||||||||||"
            p exception.message
            p "||||||||||"
            p exception.backtrace.count
            exception.backtrace.each do |x|
                next if !x.include? "invoice.rb"
                x.match(/^(.+?):(\d+)(|:in `(.+)')$/); 
               p [$1,$2,$4]
            end
            p "||||||||||"

            return {
                state: false,
                message: "Error: #{exception.message}"
            }

        end

    end



    def calculate_total

        ps_obj = {}
        total_acres = 0
        total_price = 0.0        

        # return distinct production and flight rates using the packing slip ids
        ps_ids = packing_slips.pluck(:id)
        state_ids = packing_slips.order(:state_abv).pluck(:state_id)

        p state_ids

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

        self.update(amount: total_price, acres: total_acres)

        p "done"

    end

    def nestid_report

        result = []

        ps_ids = packing_slips.pluck(:id)

        Tile.includes(:county).shipped.where(packing_slip_id: ps_ids).order(:state_abv, :county_name).each do |tile|

            result << {
                state: tile.state_abv,
                county: tile.county_name,
                full_fips: tile.county.full_fips,
                count: tile.county.tiles.count,
                shipped_count: tile.county.tiles.shipped.count,
                ship_date: tile.ship_date.strftime("%m/%d/%Y"),
                poly_id: tile.poly_id
            }
        end

        obj = {
            state: false,
            message: "Something went wrong",
            result: []
        }

        if result.size > 0
            obj = {
                state: true,
                message: "Successfully queried #{result.count} Easements for Invoice #{self.number}",
                result: result
            }
        end

        return obj

    end
    
    def nestid_export

        CSV.generate(headers: true) do |csv|

            csv << ["state", "county", "fips", "total_number_of_easements", "number_of_easements_delivered", "date_delivered", "nestid"]

            ps_ids = packing_slips.pluck(:id)

            Tile.includes(:county).shipped.where(packing_slip_id: ps_ids).order(:state_abv, :county_name).each do |tile|
                csv << [tile.state_abv, tile.county_name, tile.county.full_fips, tile.county.tiles.count, tile.county.tiles.shipped.count, tile.ship_date.strftime("%m/%d/%Y"), tile.poly_id]
            end
        end

    end

    def self.assign_psns
        ActiveRecord::Base.connection.execute("TRUNCATE invoices RESTART IDENTITY")

        invoice_15165 = ["20240329_AL", "20240329_KY", "20240401_IN", "20240401_TN", "20240401_WV", "20240404_WV", "20240405_AL", "20240405_KY", "20240405_NC", "20240405_TN", "20240406_VA", "20240407_LA", "20240408_GA"]

        invoice = Invoice.find_or_create_by!(
            number: "15165",
            invoice_date: "2024-04-10",
            project: "SL",
            amount: 0.0
        )

        PackingSlip.where(name: invoice_15165).each do |psn|
            tile = psn.tiles.first
            psn.update!(
                invoice_id: invoice.id,
                state_id: tile.state_id, 
                state_abv: tile.state_abv
            )
        end

        invoice.calculate_total

        invoice = Invoice.find_or_create_by!(
            number: "15167",
            invoice_date: "2024-04-26",
            project: "SL",
            amount: 0.0
        )

        PackingSlip.where(name: [
            "20240425_IL",
            "20240425_LA",
            "20240425_MN",
            "20240425_OH"]).each do |psn|
            tile = psn.tiles.first
            psn.update!(
                invoice_id: invoice.id,
                state_id: tile.state_id, 
                state_abv: tile.state_abv
            )
        end

        invoice.calculate_total

    end

end
