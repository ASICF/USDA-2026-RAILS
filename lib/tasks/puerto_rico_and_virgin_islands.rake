namespace :import do
    desc "Import modified State and Counties for Puerto Rico and the Virgin Islands"
    task pr_vi: :environment do
      p "Starting Puerto Rico and Virgin Island import"

        # Upload Shapefiles
        require 'rgeo/shapefile'

        if State.find_by(abv: "PR")
            p " - Detected State and County boundaries already in the database. Deleting."

            # Find the state
            state = State.find_by(abv: "PR")

            if state.present?
                # check if the state has any easements yet and if so then abort
                if state.easements.count > 0
                    p " - ERROR: #{state.name} already has easements associated. Cannot delete State."
                    return false
                else
                    p " - Deleted #{state.name} and associated Counties"

                    state.contract_awards.find_by(project: "NRI").destroy!

                    # Delete the counties and states
                    p state.counties.count
                    state.destroy
                end
            end

        end

        # Import the States
        RGeo::Shapefile::Reader.open("#{Rails.application.secrets.pr_vi_state_path}") do |file|
            p " "
            p "States"
            p "--------------------"
            file.each do |record|
                p "- State: #{record.attributes["name"]}"
                State.create(
                    fips: record.attributes["fips"],
                    abv: record.attributes["abv"],
                    name: record.attributes["name"],
                    geom: record.geometry
                )
            end
        end

        # Import the Counties
        RGeo::Shapefile::Reader.open("#{Rails.application.secrets.pr_vi_county_path}") do |file|
            p " "
            p "Counties"
            p "--------------------"

            state = State.find_by(abv: "PR")

            file.each do |record|
                p "- County: #{record.attributes["NAME"]}"
                state.counties.create(
                    fips: record.attributes["COUNTYFP"],
                    full_fips: record.attributes["GEOID"],
                    name: record.attributes["NAME"],
                    geom: record.geometry
                )
            end
        end


        # Import the Timezone
        RGeo::Shapefile::Reader.open("#{Rails.application.secrets.timezone_path}") do |file|
            p " "
            p "TimeZone"
            p "--------------------"

            timezones = TimeZone.where(name: ["Pacific/Honolulu", "America/Puerto_Rico", "America/St_Thomas"])
            timezones.each do |tz|
                if tz.easements.count > 0
                    p " - ERROR: Timezone #{tz.name} already has easements associated. Cannot delete Timezone."
                    return false
                else
                    tz.destroy
                end
            end

            file.each do |record|
                # p "++++++++++++"

                next if !["Pacific/Honolulu", "America/Puerto_Rico", "America/St_Thomas"].include? record.attributes["TZID"]
                puts "Timezone #{record.attributes["TZID"]}"

                TimeZone.create(
                    name: record.attributes["TZID"],
                    geom: record.geometry
                )
            end
        end

        # NRI Contract rates
        CSV.foreach(Rails.application.secrets.project_cost_path, {:headers => true, :header_converters => :symbol}) do |row|

            # Find the state
            state = State.find_by(abv: row[:state])

            raise Exception, "Could not find State: #{row[:state]}" if state.nil?

            next if row[:project_type] != "NRI"
            next if row[:state] != "PR"

            # Create the award
            ContractAward.create(
                project: row[:project_type],
                project_no: row[:project],
                amount: row[:total].to_d,
                flight_amount: row[:flight_price].to_d,
                production_amount: row[:prod_price].to_d,
                start_date: "2025-03-09",
                end_date: "2025-03-09",
                season_start: "2025-03-11",
                season_end: "2025-12-31",
                state: state
            )

            # Iterate the companies
            Company.all.each do |company|

                flight_rate = row[:sub_flight]
                prod_rate = row[:sub_prod]

                if company.alias == "ASI"
                    flight_rate = row[:asi_flight]
                    prod_rate = row[:asi_prod]
                end

                # Create the Contract Rates
                # Flight
                ContractRate.create(
                    project: row[:project_type],
                    project_no: row[:project],
                    company_alias: company.alias,
                    phase: 100,
                    cost: flight_rate.to_d,
                    start_date: "2025-03-09",
                    end_date: "2025-03-09",
                    state: state,
                    company: company
                )

                # Production
                ContractRate.create(
                    project: "NRI",
                    project_no: row[:project],
                    company_alias: company.alias,
                    phase: 300,
                    cost: prod_rate.to_d,
                    start_date: "2025-03-09",
                    end_date: "2025-03-09",
                    state: state,
                    company: company
                )
            end

        end

    end
  end