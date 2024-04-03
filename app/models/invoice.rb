class Invoice

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
                    csv << ["State", "County", "FIPS", "Easements", "Acres", "USDA Unit Price", "Packing Slip", "Date Shipped", "Acquisition Price", "Orthos Price", "Total Price"]
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
                                record[:acres],
                                record[:unit_price],
                                # record[:sub_unit_price],
                                record[:psn_name],
                                record[:date_shipped],
                                record[:acquisition_price],
                                record[:orthos_price],
                                record[:total_price],
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
            obj = {project: project, shipped_date: date_from..date_to}
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
                    match[:acquisition_price] += tile.flight_amount.to_f
                    match[:orthos_price] += tile.production_amount.to_f
                    match[:total_price] += tile.total_amount.to_f
                    # match[:sub_unit_price] |= [sub_unit_price] if sub_unit_price > 0
                    # match[:sub_acquisition_price] += tile.sub_flight_cost.to_f
                    # match[:sub_orthos_price] += tile.sub_production_cost.to_f
                    # match[:sub_total_price] += tile.sub_total_cost.to_f
                else
                    packing_slip = tile.packing_slip

                    # sub_unit_price = tile.flight_rate.sub_cost.to_f + tile.production_rate.sub_cost.to_f

                    state_array << {
                        state_name: tile.state_name,
                        county_name: tile.county_name,
                        fips: tile.county.full_fips,
                        count: 1,
                        acres: tile.easements_acres.to_f,
                        unit_price: tile.flight_rate.cost.to_f + tile.production_rate.cost.to_f,
                        # sub_unit_price: sub_unit_price > 0 ? [sub_unit_price] : [],
                        psn_name: "#{packing_slip.name}.pdf",
                        date_shipped: packing_slip.shipped_date.strftime("%m/%d/%Y"),
                        acquisition_price: tile.flight_amount.to_f,
                        orthos_price: tile.production_amount.to_f,
                        total_price: tile.total_amount.to_f,
                        # sub_acquisition_price: tile.sub_flight_cost.to_f,
                        # sub_orthos_price: tile.sub_production_cost.to_f,
                        # sub_total_price: tile.sub_total_cost.to_f,
                    }
                end

            end

            return {
                state: true,
                result: result
            }
          
        rescue StandardError => e
            p e.message
            return {
                state: false,
                message: "Error: #{e.message}"
            }

        end

    end

    def self.build_naip date_from, date_to

        p "build naip"

        # result = []
        result = {}

        begin
                
            # Get the packing slips that were shipped during period
            psn_ids = PackingSlip.select(:id).where(project: "NAIP", shipped_date: date_from..date_to).pluck(:id)

            p psn_ids

            Doqq.where(packing_slip_id: psn_ids).order([:state_name]).each do |doqq|

                # Create the state
                result[doqq.state_name.to_sym] = [] if result[doqq.state_name.to_sym].nil?

                state_array = result[doqq.state_name.to_sym]

                p state_array

                # check if the value exists in the array
                match = state_array.find {|a| a[:state_name] == doqq.state_name}

                p match

                if match
                    match[:count] += 1
                    match[:acres] += doqq.acres.to_f
                else
                    packing_slip = doqq.packing_slip

                    p packing_slip

                    state_array << {
                        state_name: doqq.state_name,
                        # county_name: doqq.county_name,
                        fips: doqq.state.fips,
                        count: 1,
                        acres: doqq.acres.to_f,
                        psn_name: "#{packing_slip.name}.pdf",
                        date_shipped: packing_slip.shipped_date.strftime("%Y%m%d")
                    }

                    p state_array 
                end

            end

            return {
                state: true,
                result: result
            }
          
        rescue StandardError => e
            return {
                state: false,
                message: "Error: #{e.message}"
            }

        end

    end

end
