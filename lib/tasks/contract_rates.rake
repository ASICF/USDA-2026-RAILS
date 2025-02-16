namespace :contract do
    desc "Import Contract Rates"
    task rates: :environment do
        p "Starting Contract Rates"

        # Clear all awards and rates
        ActiveRecord::Base.connection.execute("TRUNCATE contract_rates RESTART IDENTITY")

        # fields
        fields = ["project","project_no","company_alias","phase","start_date","end_date","cost","sub_cost"]

        # iterate the contract awards
        CSV.foreach(Rails.application.secrets.contract_rate_path, {:headers => true, :header_converters => :symbol}) do |row|

            p row

            obj = {}
            fields.each do |field|
                obj[field] = row[field.to_sym]
            end

            # match the state
            obj[:state_id] = State.find_by(abv: row[:state_abv]).id
            obj[:company_id] = Company.find_by(alias: row[:company_alias]).id

            # ContractRate.create(obj)

            record = ContractRate.new(obj)

            p "valid?: #{record.valid?}"
            p record.errors

            record.save

        end

    end

end