class Invoice < ApplicationRecord

    # Validation
    validates :number, :invoice_date, :project, :amount, presence: true
    validates :number, uniqueness: true

    # Associations
    has_many :packing_slips

    # Validations
    # validate :check_projects

    def export

        result, totals = build_contract_total

        CSV.generate(headers: true) do |csv|
            csv << ["State", "FIPS", "County", "Shipped Easements", "Acres", "Packing Slip", ""]

            result.each do |key, array|
                p "#{key}-----"
                # p array

                array.each do |record|
                    if project == "SL" || project == "NRI"
                        csv << [
                            record[:state_name],
                            record[:fips],
                            record[:county_name],
                            record[:count],
                            record[:acres],
                            record[:psn_name],
                            ""
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

                # add the totals
                # p "------"
                # pp totals
                # p "------"

                prev_delivery = totals[key.to_s][:previously_delivered]
                prev_billed = totals[key.to_s][:previously_billed]
                total_delivery = totals[key.to_s][:total_delivery]
                total_billing = totals[key.to_s][:total_billing]
                this_billing = totals[key.to_s][:this_billing]

                price_label = "Price Per Acre"
                if self.project == "NRI"
                    price_label = "Price Per Site"
                end

                csv << [key, "", "Previously Delivered", prev_delivery[:easements], prev_delivery[:acres], price_label, "Total"]
                csv << [key, "", "Previously Billed", prev_billed[:easements], prev_billed[:acres], prev_billed[:ppa], prev_billed[:total]]
                csv << [key, "", "Total Delivery", total_delivery[:easements], total_delivery[:acres], "", ""]
                csv << [key, "", "Total Billing", total_billing[:easements], total_billing[:acres], total_billing[:ppa], total_billing[:total]]
                csv << [key, "", "This Billing", this_billing[:easements], this_billing[:acres], this_billing[:ppa], this_billing[:total]]
                csv << [""]

            end

        end

    end

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
                    csv << ["State", "FIPS", "County", "Shipped Easements", "Acres", "Packing Slip", ""]
                else
                    csv << ["State", "FIPS", "DOQQs", "Square Miles", "File Name", "Date Shipped"]
                end

                response[:result].each do |key, array|
                    # p "#{key}-----"
                    # p array

                    array.each do |record|
                        if project == "SL" || project == "NRI"
                            csv << [
                                record[:state_name],
                                record[:fips],
                                record[:county_name],
                                record[:count],
                                record[:acres],
                                record[:psn_name],
                                ""
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

                    # add the totals
                    totals = response[:totals][key.to_s]

                    # p "------"
                    # pp totals
                    # p "------"

                    prev_delivery = totals[:previously_delivered]
                    prev_billed = totals[:previously_billed]
                    total_delivery = totals[:total_delivery]
                    total_billing = totals[:total_billing]
                    this_billing = totals[:this_billing]

                    csv << [key, "", "Previously Delivered", prev_delivery[:easements], prev_delivery[:acres], "Price Per Acre", "Total"]
                    csv << [key, "", "Previously Billed", prev_billed[:easements], prev_billed[:acres], prev_billed[:ppa], prev_billed[:total]]
                    csv << [key, "", "Total Delivery", total_delivery[:easements], total_delivery[:acres], "", ""]
                    csv << [key, "", "Total Billing", total_billing[:easements], total_billing[:acres], total_billing[:ppa], total_billing[:total]]
                    csv << [key, "", "This Billing", this_billing[:easements], this_billing[:acres], this_billing[:ppa], this_billing[:total]]
                    csv << [""]

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

                    unit_price = 0
                    if tile.project == "SL"
                        unit_price = tile.easements_acres.round(2) * tile.contract_award.ppa
                    elsif tile.project == "NRI"
                        unit_price = tile.contract_award.pps
                    end

                    state_array << {
                        state_name: tile.state_name,
                        fips: tile.county.full_fips,
                        county_name: tile.county_name,
                        count: 1,
                        acres: tile.easements_acres.to_f,
                        psn_name: "#{packing_slip.name}.pdf",
                        psn_id: packing_slip.id,
                        unit_price: unit_price,

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
                # state.packing_slips.where(project: project).where("shipped_date < ?", date_from).each do |ps|
                #     obj[:previously_delivered][:easements] += ps.tiles.count
                #     obj[:previously_delivered][:acres] += ps.tiles.sum(:easements_acres).round(0)
                # end

                # Previously billed
                # => get the packing slips that were delivered for the state before the date_from variable that have an invoice
                # ==> Total, Acres, contract amount, total
                invoice_ids = Invoice.where(packing_slips: {state_id: state.id}).where("invoice_date < ?", date_from)
                state.packing_slips.includes(:tiles).where(invoice_id: invoice_ids).each do |ps|

                    obj[:previously_delivered][:easements] += ps.tiles.count
                    obj[:previously_delivered][:acres] += ps.tiles.sum(:easements_acres).round(0)

                    obj[:previously_billed][:easements] += ps.tiles.count
                    obj[:previously_billed][:acres] += ps.tiles.sum(:easements_acres)
                end

                # calculate the total billed
                obj[:previously_billed][:total] = obj[:previously_billed][:acres] * ppa


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
                # obj[:this_billing][:acres] = tiles.sum(:easements_acres).round(0)
                # obj[:this_billing][:total] = obj[:this_billing][:acres] * ppa

                obj[:this_billing][:acres] = obj[:total_billing][:acres] - obj[:previously_billed][:acres]
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

    def build_contract_total
        result = {}

        ps_ids = packing_slips.pluck(:id)

        Tile.shipped.where(packing_slip_id: packing_slips.pluck(:id)).order([:state_name, :county_name]).each do |tile|

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
            else
                packing_slip = tile.packing_slip

                # sub_unit_price = tile.flight_rate.sub_cost.to_f + tile.production_rate.sub_cost.to_f

                unit_price = 0
                if self.project == "SL"
                    unit_price = tile.easements_acres.round(2) * tile.contract_award.ppa
                elsif self.project == "NRI"
                    unit_price = tile.contract_award.pps
                end

                state_array << {
                    state_name: tile.state_name,
                    fips: tile.county.full_fips,
                    county_name: tile.county_name,
                    count: 1,
                    acres: tile.easements_acres.to_f,
                    psn_name: "#{packing_slip.name}.pdf",
                    psn_id: packing_slip.id,
                    unit_price: unit_price,
                }
            end

        end

        # Calculate the previous delivered
        # state_obj = {packing_slips: {project: project}}
        # state_obj[:id] = state.id if !state.nil?

        state_obj = {tiles: {packing_slip_id: ps_ids}}

        totals = {}

        # get the states and find any packing slips that are not in the current psn_ids
        State.includes(packing_slips: [:tiles]).where(state_obj).each do |state|

            ca = state.contract_awards.where(project: project).first

            if self.project == "SL"
                ppa = ca.ppa
            elsif self.project == "NRI"
                ppa = ca.pps
            end

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
            # state.packing_slips.where(project: project).where("shipped_date < ?", invoice_date).each do |ps|
            #     obj[:previously_delivered][:easements] += ps.tiles.count
            #     obj[:previously_delivered][:acres] += ps.tiles.sum(:easements_acres)
            # end

            # Previously billed
            # => get the packing slips that were delivered for the state before the date_from variable that have an invoice
            # ==> Total, Acres, contract amount, total
            invoice_ids = Invoice.where(packing_slips: {state_id: state.id}).where("invoice_date < ?", invoice_date)
            state.packing_slips.includes(:tiles).where(invoice_id: invoice_ids).each do |ps|

                obj[:previously_delivered][:easements] += ps.tiles.count
                obj[:previously_delivered][:acres] += ps.tiles.sum(:easements_acres)

                obj[:previously_billed][:easements] += ps.tiles.count
                obj[:previously_billed][:acres] += ps.tiles.sum(:easements_acres).round(0)
            end

            # calculate the total billed
            if self.project == "SL"
                obj[:previously_billed][:total] = obj[:previously_billed][:acres] * ppa
            elsif self.project == "NRI"
                obj[:previously_billed][:total] = obj[:previously_billed][:easements] * ppa
            end

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

            if self.project == "SL"
                obj[:total_billing][:total] = obj[:total_billing][:acres] * ppa
            elsif self.project == "NRI"
                obj[:total_billing][:total] = obj[:total_billing][:easements] * ppa
            end

            # This Billing
            # calcualte using the psn_ids

            # check if the packing slip
            tiles = state.tiles.shipped.where(packing_slip_id: ps_ids)
            obj[:this_billing][:easements] = tiles.count
            # obj[:this_billing][:acres] = tiles.sum(:easements_acres).round(0)
            # obj[:this_billing][:total] = obj[:this_billing][:acres] * ppa

            obj[:this_billing][:acres] = obj[:total_billing][:acres] - obj[:previously_billed][:acres]
            obj[:this_billing][:total] = obj[:this_billing][:acres] * ppa

            if self.project == "SL"
                obj[:this_billing][:total] = obj[:this_billing][:acres] * ppa
            elsif self.project == "NRI"
                obj[:this_billing][:total] = obj[:this_billing][:easements] * ppa
            end


            # p " ------------- "
            # pp obj
            # p " ------------- "

            totals[state.name] = obj

        end

        return result, totals

    end

    def calculate_total

        result, totals = build_contract_total

        acres = 0
        amount = 0.0
        totals.each do |total, obj|
            # p total
            # p obj
            acres += obj[:this_billing][:acres]
            amount += obj[:this_billing][:total]
        end

        # pp result
        # p "-------"
        # p amount
        # p acres

        self.update(amount: amount, acres: acres)

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

            csv << ["state", "county", "fips", "total_number_of_easements", "number_of_easements_delivered", "date_delivered", "nestid", "flight_date", ]

            ps_ids = packing_slips.pluck(:id)

            Tile.includes(:county).shipped.where(packing_slip_id: ps_ids).order(:state_abv, :county_name).each do |tile|
                csv << [tile.state_abv, tile.county_name, tile.county.full_fips, tile.county.tiles.count, tile.county.tiles.shipped.count, tile.ship_date.strftime("%m/%d/%Y"), tile.poly_id, tile.flight_date.strftime("%m/%d/%Y")]
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

    private

    # def check_projects

    #     p "---"
    #     p packing_slips
    #     p project
    #     p "---"

    #     if packing_slips.where.not(project: project).count > 0
    #         errors.add(:title, "multiple Projects found in packing slips, must be NRI or SL")
    #     end
    # end

end
