ActiveRecord::Base.connection.execute("TRUNCATE users RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE companies RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE planes RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE cameras RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE easements RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE tiles RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE footprints RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE frame_centers RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE rejected_tiles RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE rejected_footprints RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE rejected_frame_centers RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE states RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE counties RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE utms RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE mail_groups RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE mail_group_users RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE contract_awards RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE contract_rates RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE histories RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE historic_assocs RESTART IDENTITY")
ActiveRecord::Base.connection.execute("TRUNCATE jobs RESTART IDENTITY")

if Rails.env.development?
    # Create user
    admin = User.create(
        email: Rails.application.secrets.admin[:email], 
        first_name: Rails.application.secrets.admin[:first_name], 
        last_name: Rails.application.secrets.admin[:last_name], 
        title: Rails.application.secrets.admin[:title], 
        approved: true,
        role: "Admin",
        password: Rails.application.secrets.admin[:password],
        password_confirmation: Rails.application.secrets.admin[:password]
    )
end

# Create some companies
# ASI
# -----------------------------
company = Company.create(
    name: "Aerial Services, Inc",
    alias: "ASI"
)

# Planes
company.planes.create(
    name: "N78AS",
    model: "Cessna TU206H"
)
company.planes.create(
    name: "N144AS",
    model: "Piper Navajo PA31-310"
)
company.planes.create(
    name: "N756QV",
    model: "Cessna TU206G"
)
company.planes.create(
    name: "N72RK",
    model: "Cessna TU206H"
)

# Cameras
company.cameras.create(
    name: "1300",
    manufacturer: "Leica",
    model: "ADS80",
    serial_number: "763806_1300_090130-1"
)
company.cameras.create(
    name: "1301",
    manufacturer: "Leica",
    model: "ADS80",
    serial_number: "763806_1301_080926-1"
)
company.cameras.create(
    name: "82553",
    manufacturer: "Leica",
    model: "RCD-30",
    serial_number: "791649_82553_180711-1"
)
company.cameras.create(
    name: "UC-Fp-1-20317121-f100",
    manufacturer: "Vexcel",
    model: "UltraCam Falcon",
    serial_number: "UC-Fp-1-20317121-f100 V4.0"
)
# -----------------------------

# Aerodata
# -----------------------------
company = Company.create(
    name: "Aerodata",
    alias: "AER"
)
# Planes
company.planes.create(
    name: "N51CX",
    model: "Cessna 340A"
)
company.planes.create(
    name: "N63CX",
    model: "Cessna 414"
)
company.planes.create(
    name: "N262AS",
    model: "Piper Navajo PA31"
)
# Cameras
company.cameras.create(
    serial_number: "DMC III 27546",
    manufacturer: "Leica",
    model: "DMC III",
    name: "00129126 (PAN Head)"
)
company.cameras.create(
    serial_number: "DMC III 27551",
    manufacturer: "Leica",
    model: "DMC III",
    name: "00129129 (PAN Head)"
)
# -----------------------------

# Midwest Aerial Photography
# -----------------------------
company = Company.create(
    name: "Midwest Aerial Photography",
    alias: "MAP"
)
# Planes
company.planes.create(
    name: "N4032C",
    model: "Cessna 310-R"
)
company.planes.create(
    name: "N5083J",
    model: "Cessna 310-R"
)
company.planes.create(
    name: "N211TN",
    model: "Piper PA-27 Aztec"
)
company.planes.create(
    name: "N7052H",
    model: "Piper PA-27 Aztec"
)
# Cameras
company.cameras.create(
    name: "23526",
    manufacturer: "Intergraph",
    model: "DMC IIe 230",
    serial_number: "DMC IIe 230-23526"
)
company.cameras.create(
    name: "036",
    manufacturer: "Intergraph",
    model: "DMC II 140",
    serial_number: "DMC II 140 -036"
)
# -----------------------------

# GRW
# -----------------------------
company = Company.create(
    name: "GRW",
    alias: "GRW"
)
# Planes
company.planes.create(
    name: "N83PA",
    model: "Piper Navajo PA-31-325"
)
company.planes.create(
    name: "N85PE",
    model: "Cessna TU206F"
)
# Cameras
company.cameras.create(
    name: "UC-E-1-50111116-f100",
    manufacturer: "Vexcel",
    model: "UltraCam Eagle",
    serial_number: "UC-E-1-50111116-f100 V01"
)
company.cameras.create(
    name: "UCLP-1-10113213",
    manufacturer: "Vexcel",
    model: "UltraCamLP",
    serial_number: "UC-Lp-1-10113213 V15.0"
)
# -----------------------------


# ADS
# -----------------------------
company = Company.create(
    name: "Aerial Data Services",
    alias: "ADS"
)
# Planes
company.planes.create(
    name: "N4073L",
    model: "Piper Navajo PA-31-350"
)
# Cameras
company.cameras.create(
    name: "UC-F-1-30710015-f100",
    manufacturer: "Vexcel",
    model: "UltraCam Falcon",
    serial_number: "UC-F030710015-f100 V04"
)
# -----------------------------

# Williams Aerial and Mapping
# -----------------------------
company = Company.create(
    name: "Williams Aerial and Mapping",
    alias: "WAM"
)
# Planes
company.planes.create(
    name: "N150V",
    model: "Cessna TU206G"
)
company.planes.create(
    name: "N92HC",
    model: "Cessna TU206F"
)
company.planes.create(
    name: "N64AP",
    model: "Piper Navajo PA-31-350"
)
company.planes.create(
    name: "N310EW",
    model: "Cessna T310Q"
)
company.planes.create(
    name: "N91PW",
    model: "Piper Navajo PA-31-350"
)
# Cameras
company.cameras.create(
    name: "UC-F-1-50118074-f100",
    manufacturer: "Vexcel",
    model: "UltraCam Falcon",
    serial_number: "UC-F-1-50118074-f100 V01"
)
# -----------------------------

# Arrowhawk
# -----------------------------
company = Company.create(
    name: "Arrowhawk",
    alias: "AHK"
)
# Planes
company.planes.create(
    name: "N213SM",
    model: "Cessna TU206"
)
# Cameras
company.cameras.create(
    name: "431S91198X311374-f100",
    manufacturer: "Vexcel",
    model: "UltraCam Eagle M3",
    serial_number: "431S91198X311374-f100 v01"
)
# -----------------------------

# Technical Applications & Consulting
# -----------------------------
company = Company.create(
    name: "Technical Applications & Consulting",
    alias: "TAC"
)
# Planes
company.planes.create(
    name: "N8647Q",
    model: "Cessna TU206"
)
company.planes.create(
    name: "N78MW",
    model: "Cessna TU206"
)
company.planes.create(
    name: "N528NR",
    model: "Cessna T310R"
)
# Cameras
company.cameras.create(
    name: "1318",
    manufacturer: "Leica",
    model: "ADS80",
    serial_number: "763806_1318_091209-1"
)
company.cameras.create(
    name: "UC-Lp-1-70410266",
    manufacturer: "Vexcel",
    model: "UltraCam LP",
    serial_number: "UC-Lp-1-70410266 V4.0"
)
# -----------------------------

# CT Consultants, Inc
# -----------------------------
company = Company.create(
    name: "CT Consultants, Inc",
    alias: "CTC"
)
# Planes
company.planes.create(
    name: "N39BT",
    model: "Cessna T310Q"
)
# Cameras
company.cameras.create(
    name: "YZ000032",
    manufacturer: "Phase One",
    model: "iXM-RS280 F",
    serial_number: "YZ000032"
)
# -----------------------------

# The Atlantic Group
# -----------------------------
company = Company.create(
    name: "The Atlantic Group",
    alias: "ATL"
)
# Planes
company.planes.create(
    name: "N167PM",
    model: "Cessna 208"
)
company.planes.create(
    name: "N108RF",
    model: "Cessna 208"
)
company.planes.create(
    name: "N750VX",
    model: "PAC750"
)
company.planes.create(
    name: "N750DV",
    model: "PAC750"
)
# Cameras
company.cameras.create(
    name: "033",
    manufacturer: "Intergraph",
    model: "DMC 1",
    serial_number: "DMC01-0033"
)
company.cameras.create(
    name: "001",
    manufacturer: "Intergraph",
    model: "DMC 1",
    serial_number: "DMC01-0001"
)
company.cameras.create(
    name: "YZ000022",
    manufacturer: "Phase One",
    model: "iXM-RS280 F",
    serial_number: "YZ000022"
)
# -----------------------------

# Aerial Surveys International
# -----------------------------
company = Company.create(
    name: "Aerial Surveys International",
    alias: "ASI"
)
# Planes
company.planes.create(
    name: "N1008A",
    model: "Cessna 402"
)
company.planes.create(
    name: "N2JJ",
    model: "Cessna 402"
)
# Cameras
company.cameras.create(
    name: "137",
    manufacturer: "Intergraph",
    model: "DMC 1",
    serial_number: "DMC01-0137"
)
company.cameras.create(
    name: "121",
    manufacturer: "Intergraph",
    model: "DMC 1",
    serial_number: "DMC01-0121"
)
# -----------------------------

# Helios Airborne Solutions
# -----------------------------
company = Company.create(
    name: "Helios Airborne Solutions",
    alias: "HAS"
)
# Planes
company.planes.create(
    name: "N14NN",
    model: "Cessna TU206G"
)
# Cameras
company.cameras.create(
    name: "005",
    manufacturer: "Intergraph",
    model: "DMC II",
    serial_number: "DMCII40-005"
)
# -----------------------------

# GPI Geospatial
# -----------------------------
company = Company.create(
    name: "GPI Geospatial",
    alias: "ASI"
)
# Planes
company.planes.create(
    name: "N27GP",
    model: "Cessna TU206G"
)
company.planes.create(
    name: "N26GP",
    model: "Piper Navajo PA-31-325"
)
company.planes.create(
    name: "N9481T",
    model: "Cessna TU206G"
)
# Cameras
company.cameras.create(
    name: "UC-EpII-22411214-f100",
    manufacturer: "Vexcel",
    model: "UltraCam Eagle M3",
    serial_number: "UC-EpII-22411214-f100 V01"
)
# -----------------------------

# Build Mail Groups

# Imports and Status
# MailGroup.create(name: "Last Footprints Uploaded for the Day", description: "Notifies group when a user checks the box on the Footprint Import that the last Footprints are being uploaded for the day")
MailGroup.create(name: "Footprints", description: "Notifies group when someone Uploads a Footprint Shapefile")
MailGroup.create(name: "Photo Index", description: "Notifies group when someone Uploads a Photo Index File")
MailGroup.create(name: "AT Done", description: "Notifies the group when the EO is imported and the associated Tiles are marked as AT Done.")
MailGroup.create(name: "Ortho Processing", description: "Notifies group when the Cutfile is created and the Ortho Processing has been set to Tiles")
MailGroup.create(name: "Tile Dump", description: "Notifies group when the Tile Dump has been completed")
MailGroup.create(name: "Final Delivery", description: "Notifies group when the Final Delivery has been completed")
MailGroup.create(name: "USDA Approved", description: "Notifies group when someone updates a packing slip that it has been accepted by the USDA and can be invoiced.")
MailGroup.create(name: "Excel Export", description: "Notifies the group when someone exports the Excel report.")
MailGroup.create(name: "EAWS", description: "Notifies the group when imports/exports related to the Early Access Web Services are generated.")

# Daily
MailGroup.create(name: "Daily Progress Report", description: "Sends an email when the Daily Progress report has been completed or if there is any Reports that are overdue.")
MailGroup.create(name: "Ready to Ship", description: "Daily reminder of what Tiles are ready to ship sent at 8AM. If no Tiles are ready then it will confirm in the email.")

# Rejections and Coverages
MailGroup.create(name: "Easements with Multiple Coverages", description: "Notifies the group when the system checks that an Easement is covered by multiple Footprints of different flight dates or is unrejected and there are Footprints that cover it.")
MailGroup.create(name: "Rejection", description: "Email is sent when a Tile has been rejected, either manually or automatically with the Photo Index or Frame Center Imports.")

# Sanity
MailGroup.create(name: "Email Relay Check", description: "Daily Email that's only purpose is to verify the email relay is working")

# Daily audit check
MailGroup.create(name: "Audit", description: "Email is sent during the Quick or Nightly Audits to notify of potential errors within the application.")
MailGroup.create(name: "Errors", description: "Group is notified when critical errors are found due to crashes or catches.")

if Rails.env.development?
    # add admin to mailgroups
    MailGroup.all.each { |mg| mg.users << admin }
else
    mg = MailGroup.find_by(name: "AT Done")
    Rails.application.secrets.at_done_users.each {|obj| mg.users << User.find_by(obj) }

    mg = MailGroup.find_by(name: "Ready to Ship")
    Rails.application.secrets.ready_to_ship_users.each {|obj| mg.users << User.find_by(obj) }

    mg = MailGroup.find_by(name: "Rejection")
    Rails.application.secrets.rejection_users.each {|obj| mg.users << User.find_by(obj) }

    mg = MailGroup.find_by(name: "Errors")
    Rails.application.secrets.error_users.each {|obj| mg.users << User.find_by(obj) }

    mg = MailGroup.find_by(name: "USDA Approved")
    Rails.application.secrets.usda_approved_users.each {|obj| mg.users << User.find_by(obj) }

    mg = MailGroup.find_by(name: "Audit")
    Rails.application.secrets.audit_users.each {|obj| mg.users << User.find_by(obj) }

    mg = MailGroup.find_by(name: "Final Delivery")
    Rails.application.secrets.packing_slip.each {|obj| mg.users << User.find_by(obj) }

    mg = MailGroup.find_by(name: "Photo Index")
    Rails.application.secrets.photo_index.each {|obj| mg.users << User.find_by(obj) }
end

# -----------------------------

# Upload Shapefiles
require 'rgeo/shapefile'

# Import the States
RGeo::Shapefile::Reader.open("#{Rails.application.secrets.state_path}") do |file|
    # puts "File contains #{file.num_records} records."
    p "States"
    p "--------------------"
    file.each do |record|

        # p "------------"
        # p "checking: #{record.attributes["STUSPS"]}"
        # p Rails.application.secrets.active_states.include?(record.attributes["STUSPS"])
        # p State.find_by(abv: record.attributes["STUSPS"]).nil?

        # if Rails.application.secrets.active_sl_states.include?(record.attributes["STUSPS"]) && State.find_by(abv: record.attributes["STUSPS"]).nil? || Rails.application.secrets.active_naip_states.include?(record.attributes["STUSPS"]) && State.find_by(abv: record.attributes["STUSPS"]).nil?
        if (Rails.application.secrets.active_sl_states.include?(record.attributes["STUSPS"]) || Rails.application.secrets.active_nri_states.include?(record.attributes["STUSPS"]) ) && State.find_by(abv: record.attributes["STUSPS"]).nil? 

            puts "MATCH: #{record.attributes["STUSPS"]}"
            # puts "Record number #{record.index}:"
            # puts "  Geometry: #{record.geometry.as_text}"
            # puts "  Attributes: #{record.attributes.inspect}"
            State.create(
                fips: record.attributes["STATEFP"],
                abv: record.attributes["STUSPS"],
                name: record.attributes["NAME"],
                geom: record.geometry
            )
        end
    end
end

# # Import the Counties
RGeo::Shapefile::Reader.open("#{Rails.application.secrets.county_path}") do |file|
    # puts "File contains #{file.num_records} records."
    p "Counties"
    p "--------------------"

    file.each do |record|

        state = State.find_by(fips: record.attributes["STATEFP"])

        if state.present? && state.easements.count == 0

            puts "Matched #{state.name} - Record number #{record.index}:"
            # puts "  Geometry: #{record.geometry.as_text}"
            # puts "  Attributes: #{record.attributes.inspect}"
            # state = State.where(fips: record.attributes["STATEFP"]).first
            state.counties.create(
                fips: record.attributes["COUNTYFP"],
                full_fips: record.attributes["GEOID"],
                name: record.attributes["NAME"],
                geom: record.geometry
            )
        end
    end
end

# Import the UTM
RGeo::Shapefile::Reader.open("#{Rails.application.secrets.utm_path}") do |file|
    # puts "File contains #{file.num_records} records."
    p "UTM"
    p "--------------------"
    file.each do |record|
        p "++++++++++++"
        puts "Record number #{record.index}:"
        # puts "  Geometry: #{record.geometry.as_text}"
        # puts "  Attributes: #{record.attributes.inspect}"

        p !(10..19).to_a.include?(record.attributes["ZONE"].to_i)
        p Utm.find_by(zone: record.attributes["ZONE"]).present?
        p "++++++++++++"

        next if !(10..19).to_a.include?(record.attributes["ZONE"].to_i)
        next if Utm.find_by(zone: record.attributes["ZONE"]).present?

        # puts "Record number #{record.index}:"

        Utm.create(
            # swlon: record.attributes["swlon"],
            # swlat: record.attributes["swlat"],
            hemisphere: "N",
            zone: record.attributes["ZONE"],
            geom: record.geometry
        )
    end
end


# Import the Timezone
RGeo::Shapefile::Reader.open("#{Rails.application.secrets.timezone_path}") do |file|
    # puts "File contains #{file.num_records} records."
    p "TimeZone"
    p "--------------------"
    file.each do |record|
        # p "++++++++++++"
        puts "Timezone #{record.attributes["TZID"]}"

        TimeZone.create(
            name: record.attributes["TZID"],
            geom: record.geometry
        )
    end
end

# SL Contract Rates
CSV.foreach(Rails.application.secrets.project_cost_path, {:headers => true, :header_converters => :symbol}) do |row|

    # Find the state
    state = State.find_by(name: row[:state])

    raise Exception, "Could not find State: #{row[:state]}" if state.nil?

    # Create the award
    ContractAward.create(
        project: "SL",
        project_no: row[:project],
        amount: row[:total].to_d,
        flight_amount: row[:flight_price].to_d,
        production_amount: row[:prod_price].to_d,
        start_date: "2024-02-09",
        end_date: "2025-02-08",
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
            project: "SL",
            project_no: row[:project],
            company_alias: company.alias,
            phase: 100,
            cost: flight_rate.to_d,
            start_date: "2024-02-09",
            end_date: "2025-02-08",
            state: state,
            company: company
        )

        # Production
        ContractRate.create(
            project: "SL",
            project_no: row[:project],
            company_alias: company.alias,
            phase: 300,
            cost: prod_rate.to_d,
            start_date: "2024-02-09",
            end_date: "2025-02-08",
            state: state,
            company: company
        )
    end

end

# NRI Contract rates
CSV.foreach(Rails.application.secrets.project_cost_path, {:headers => true, :header_converters => :symbol}) do |row|

    # Find the state
    state = State.find_by(name: row[:state])

    raise Exception, "Could not find State: #{row[:state]}" if state.nil?

    # Create the award
    ContractAward.create(
        project: "NRI",
        project_no: row[:project],
        amount: row[:total].to_d,
        flight_amount: row[:flight_price].to_d,
        production_amount: row[:prod_price].to_d,
        start_date: "2024-02-09",
        end_date: "2025-02-08",
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
            project: "NRI",
            project_no: row[:project],
            company_alias: company.alias,
            phase: 100,
            cost: flight_rate.to_d,
            start_date: "2024-02-09",
            end_date: "2025-02-08",
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
            start_date: "2024-02-09",
            end_date: "2025-02-08",
            state: state,
            company: company
        )
    end

end

# iterate the states
# => SL
State.active_sl.each do |state|

    p state.name
    
    # Update the Easements and Tiles
    contract_award = ContractAward.find_by(state: state, project: "SL")

    # update the easements with the state
    state.easements.sl.update(contract_award: contract_award)
    state.tiles.sl.update(contract_award: contract_award)

    # update the flown tiles
    state.tiles.sl.flown.each { |tile| tile.set_contract_rate }

end

# => NRI
State.active_nri.each do |state|

    p state.name
    
    # Update the Easements and Tiles
    contract_award = ContractAward.find_by(state: state, project: "NRI")

    # update the easements with the state
    state.easements.nri.update(contract_award: contract_award)
    state.tiles.nri.update(contract_award: contract_award)

    # update the flown tiles
    state.tiles.nri.flown.each { |tile| tile.set_contract_rate }

end

return

# update the contract rates
ContractRate.where(company_alias: "AHK", state_id: State.find_by(abv: "NJ")).update(cost: 0.85)

# Update all state rates to match ASI rate
# Update all contract rates to match

Tile.where.not(flown_by_id: 1).update(flight_rate_id: nil, production_rate_id: nil)

State.all.each do |state|

    # get the ASI rate
    flight_rate = ContractRate.find_by(state: state, company_id: 1, phase: "100").cost
    prod_rate = ContractRate.find_by(state: state, company_id: 1, phase: "300").cost

    puts "flight_rate #{flight_rate} - prod_rate #{prod_rate}"

    # iterate all non ASI companies and update their rates
    Company.where.not(id: 1).each do |company|
        # p company

        ContractRate.find_by(state: state, company: company, phase: "100").update!(cost: flight_rate)
        ContractRate.find_by(state: state, company: company, phase: "300").update!(cost: prod_rate)
    end

end

# iterate all non asi tiles and redo the contract rate
Tile.where(flown_by_id: Company.where.not(id: 1).pluck(:id)).each do |tile|
    tile.set_contract_rate
end


# ArrowHawk - AHK
company = Company.find(7)
ContractRate.find_by(company: company, state: State.find_by(abv: "NJ"), phase: "100").update(sub_cost: 0.85)
ContractRate.find_by(company: company, state: State.find_by(abv: "NY"), phase: "100").update(sub_cost: 0.85)
ContractRate.find_by(company: company, state: State.find_by(abv: "PA"), phase: "100").update(sub_cost: 0.85)
ContractRate.find_by(company: company, state: State.find_by(abv: "VT"), phase: "100").update(sub_cost: 0.70)
ContractRate.find_by(company: company, state: State.find_by(abv: "NH"), phase: "100").update(sub_cost: 0.70)
ContractRate.find_by(company: company, state: State.find_by(abv: "CT"), phase: "100").update(sub_cost: 0.81)
ContractRate.find_by(company: company, state: State.find_by(abv: "ME"), phase: "100").update(sub_cost: 0.94)
ContractRate.find_by(company: company, state: State.find_by(abv: "MA"), phase: "100").update(sub_cost: 0.81)

# AeroData - AER
company = Company.find(2)
ContractRate.find_by(company: company, state: State.find_by(abv: "MI")).update(sub_cost: 0.85)

# GRW
company = Company.find(4)
ContractRate.find_by(company: company, state: State.find_by(abv: "DE"), phase: "100").update(sub_cost: 0.85)
ContractRate.find_by(company: company, state: State.find_by(abv: "MD"), phase: "100").update(sub_cost: 0.85)
ContractRate.find_by(company: company, state: State.find_by(abv: "NC"), phase: "100").update(sub_cost: 0.85)
ContractRate.find_by(company: company, state: State.find_by(abv: "VA"), phase: "100").update(sub_cost: 0.85)
ContractRate.find_by(company: company, state: State.find_by(abv: "WV"), phase: "100").update(sub_cost: 0.85)

# Midwest Aerial
company = Company.find(3)
ContractRate.find_by(company: company, state: State.find_by(abv: "OH"), phase: "100").update(sub_cost: 0.70)

# Williams Aerial
company = Company.find(6)
ContractRate.find_by(company: company, state: State.find_by(abv: "NC"), phase: "100").update(sub_cost: 0.70)
ContractRate.find_by(company: company, state: State.find_by(abv: "VA"), phase: "100").update(sub_cost: 0.70)
ContractRate.find_by(company: company, state: State.find_by(abv: "WV"), phase: "100").update(sub_cost: 0.70)


# iterate all non asi tiles and redo the contract rate
Tile.where(flown_by_id: Company.where.not(id: 1).pluck(:id)).each do |tile|
    tile.set_contract_rate
end

# RejectedTile.all.each do |rt|

#     flight_amount = rt.flight_rate.cost.to_d * rt.easements_acres
#     production_amount = rt.production_rate.cost.to_d * rt.easements_acres

#     sub_flight_amount = rt.flight_rate.sub_cost.to_d * rt.easements_acres
#     sub_production_amount = rt.production_rate.sub_cost.to_d * rt.easements_acres

#     rt.update(
#         flight_amount: flight_amount,
#         production_amount: production_amount,
#         total_amount: flight_amount + production_amount,
#         sub_flight_cost: sub_flight_amount,
#         sub_production_cost: sub_production_amount,
#         sub_total_cost: sub_flight_amount + sub_production_amount,
#     )
# end

p "Done"