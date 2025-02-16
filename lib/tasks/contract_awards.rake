namespace :contract do
    desc "Import Contract Awards"
    task awards: :environment do
        p "Starting Contract Awards"

        # Clear all awards and rates
        ActiveRecord::Base.connection.execute("TRUNCATE contract_awards RESTART IDENTITY")

        # fields
        fields = ["project", "project_no", "amount", "flight_amount", "production_amount", "start_date", "end_date", "season_start", "season_end", "ppa", "pps"]
        
        # iterate the contract awards
        CSV.foreach(Rails.application.secrets.contract_award_path, {:headers => true, :header_converters => :symbol}) do |row|

            p row

            obj = {}
            fields.each do |field|
                # p "#{field}: #{row[field.to_sym]}"
                obj[field] = row[field.to_sym]
            end

            # match the state
            obj[:state_id] = State.find_by(abv: row[:state_abv]).id

            ContractAward.create(obj)

            # record = ContractAward.new(obj)

            # p "valid?: #{record.valid?}"
            # p record.errors

            # record.save

        end


        # states = {}
        # State.active.each do |state|
        #     states[state.abv] = state.id
        # end

        # companies = Company.all.select(:id, :name, :alias)

        # CSV.foreach(Rails.application.secrets.contract_award_path, {:headers => true, :header_converters => :symbol}) do |row|

        #     # p row

        #     state_abv = row[:state]
        #     project = row[:project_type]
        #     flight_price = row[:flight_price].to_d
        #     prod_price = row[:prod_price].to_d
        #     asi_flight = row[:asi_flight].to_d
        #     asi_prod = row[:asi_prod].to_d

        #     # get the state id
        #     state_id = states[state_abv]

        #     season_start = "2025-03-11"
        #     season_end = "2025-09-30"
        #     season_extension = "2025-09-30"

        #     if project == "NRI"
        #         season_start = "2025-03-11"
        #         season_end = "2025-12-31"
        #         season_extension = nil
        #     end

        #     # Create the award
        #     ContractAward.create(
        #         project: project,
        #         project_no: row[:project],
        #         amount: row[:total].to_d,
        #         flight_amount: flight_price.to_d,
        #         production_amount: flight_price.to_d,
        #         start_date: "2025-03-09",
        #         end_date: "2025-03-09",
        #         season_start: season_start,
        #         season_end: season_end,
        #         season_extension: season_extension,
        #         state_id: state_id
        #     )

        #     # ContractAward.find_by(project: project, state_id: state_id).update(
        #     #     flight_amount: flight_price, 
        #     #     production_amount: prod_price
        #     # )

        #     companies.each do |company|

        #         # Create the Contract Rates
        #         # Flight
        #         ContractRate.create(
        #             project: row[:project_type],
        #             project_no: row[:project],
        #             company_alias: company.alias,
        #             phase: 100,
        #             cost: row[:asi_flight].to_d,
        #             sub_cost: row[:sub_flight].to_d,
        #             start_date: "2025-03-09",
        #             end_date: "2025-03-09",
        #             state_id: state_id,
        #             company: company
        #         )

        #         # Production
        #         ContractRate.create(
        #             project: row[:project_type],
        #             project_no: row[:project],
        #             company_alias: company.alias,
        #             phase: 300,
        #             cost: row[:asi_prod].to_d,
        #             sub_cost: row[:sub_prod].to_d,
        #             start_date: "2025-03-09",
        #             end_date: "2025-03-09",
        #             state_id: state_id,
        #             company: company
        #         )

        #         # if project === "SL"

        #         #     # find the contract rates
        #         #     # => Flight
        #         #     ContractRate.find_by(state_id: state_id, project: project, company_id: company_id, phase: "100").update(cost: asi_flight)
        #         #     # => Production
        #         #     ContractRate.find_by(state_id: state_id, project: project, company_id: company_id, phase: "300").update(cost: asi_prod)

        #         # else


        #         #     # Create the Contract Rates
        #         #     # Flight
        #         #     ContractRate.create(
        #         #         project: project,
        #         #         project_no: row[:project],
        #         #         company_alias: company.alias,
        #         #         phase: 100,
        #         #         cost: asi_flight,
        #         #         start_date: "2025-03-09",
        #         #         end_date: "2025-03-09",
        #         #         state_id: state_id,
        #         #         company: company
        #         #     )

        #         #     # Production
        #         #     ContractRate.create(
        #         #         project: "NRI",
        #         #         project_no: row[:project],
        #         #         company_alias: company.alias,
        #         #         phase: 300,
        #         #         cost: asi_prod,
        #         #         start_date: "2025-03-09",
        #         #         end_date: "2025-03-09",
        #         #         state_id: state_id,
        #         #         company: company
        #         #     )
        #         # end
                
        #     end
            

        #     # update


        # end

        # Tile.flown.each {|tile| tile.set_contract_rate}

    end

end