require 'csv'

CSV.foreach(Rails.root.join('/vol1/Programming_USDA_App/2026/deploy/NRI2026_ASI_Easements.csv'), headers: true) do |row|
    # puts row['START']
    # puts row['END']
    # p row['POLY_ID']

    start_date = Date.strptime(row['START'], "%m%d%Y");
    end_date = Date.strptime(row['END'], "%m%d%Y");

    easement = Easement.nri.find_by(poly_id: row['POLY_ID'])

    p row['POLY_ID'] if easement.nil?

    easement.update(
        start_date: start_date,
        end_date: end_date
    )
end

## update SL
Easement.sl.update_all(
    start_date: "2026-02-01",
    end_date: "2026-09-30"
)


# require 'rgeo/shapefile'
# require 'dbf'

# # Create db; rake db:create db:migrate
# # or rollback db; rake db:rollback STEP=1000 db:migrate
# # seed db: rake db:seed
# # run pr_vi: rake import:pr_vi
# # run awards: rake contract:rates
# # run awards: rake contract:awards

# # rake db:seed import:pr_vi contract:rates contract:awards

# module DBF
#   module ColumnType
#     class String
#       def type_cast(value)
#         value.to_s.encode("utf-8", invalid: :replace, undef: :replace)
#       end
#     end
#   end
# end

# # RGeo::Shapefile::Reader.open(
# #   "/media/sf_SharedFolder/2026/boundaries/dissolved_pr/dissolved_pr.shp"
# # ) do |file|
# #   file.each do |record|
# #     new_geom_wkt = record.geometry.as_text.gsub(/\s+/, ' ').strip.gsub("'", "''")

# #     ActiveRecord::Base.connection.execute(<<~SQL)
# #       UPDATE counties
# #       SET geom = ST_Multi(ST_Union(geom::geometry, ST_GeomFromText('#{new_geom_wkt}', 4326)))::geography
# #       WHERE id = 849;
# #     SQL

# #     ActiveRecord::Base.connection.execute(<<~SQL)
# #       UPDATE states
# #       SET geom = ST_Multi(ST_Union(geom::geometry, ST_GeomFromText('#{new_geom_wkt}', 4326)))::geography
# #       WHERE id = 28;
# #     SQL
# #   end
# # end

# # return

# ActiveRecord::Base.connection.execute("TRUNCATE users RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE companies RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE planes RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE cameras RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE easements RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE tiles RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE footprints RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE frame_centers RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE rejected_tiles RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE rejected_footprints RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE rejected_frame_centers RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE states RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE counties RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE utms RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE mail_groups RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE mail_group_users RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE contract_awards RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE contract_rates RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE histories RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE historic_assocs RESTART IDENTITY")
# ActiveRecord::Base.connection.execute("TRUNCATE jobs RESTART IDENTITY")

# if Rails.env.development?
#     # Create user
#     admin = User.create(
#         email: Rails.application.secrets.admin[:email], 
#         first_name: Rails.application.secrets.admin[:first_name], 
#         last_name: Rails.application.secrets.admin[:last_name], 
#         title: Rails.application.secrets.admin[:title], 
#         approved: true,
#         role: "Admin",
#         password: Rails.application.secrets.admin[:password],
#         password_confirmation: Rails.application.secrets.admin[:password]
#     )
# end

# # Create some companies
# # ASI
# # -----------------------------
# company = Company.create(
#     name: "Aerial Services, Inc",
#     alias: "ASI"
# )

# # Planes
# company.planes.create(
#     name: "N4951F",
#     model: "Cessna TU206A"
# )
# company.planes.create(
#     name: "N72RK",
#     model: "Cessna TU206H"
# )
# company.planes.create(
#     name: "N78AS",
#     model: "Cessna TU206H"
# )
# company.planes.create(
#     name: "N6410N",
#     model: "Cessna TU206H"
# )
# company.planes.create(
#     name: "N225MA",
#     model: "Cessna TU206H"
# )

# # N4951F
# # N72RK
# # N78AS
# # N6410N
# # N225MA

# # UltraCam Condor Mark 1
# # - Serial: 430S21366x316031-f100

# # UltraCam Falcon Prime
# # - Serial: UC-Fp-1-20317121-f100

# # UltraCam Falcon M2
# # - Serial: UC-Fp-1-80912163-f100v2


# # Cameras
# company.cameras.create(
#     name: "430S21366x316031-f100",
#     manufacturer: "Vexcel",
#     model: "UltraCam Condor Mark 1",
#     serial_number: "430S21366x316031-f100"
# )
# company.cameras.create(
#     name: "UC-Fp-1-20317121-f100",
#     manufacturer: "Vexcel",
#     model: "UltraCam Falcon Prime",
#     serial_number: "UC-Fp-1-20317121-f100"
# )
# company.cameras.create(
#     name: "UC-Fp-1-80912163-f100v2",
#     manufacturer: "Vexcel",
#     model: "UltraCam Falcon M2",
#     serial_number: "UC-Fp-1-80912163-f100v2"
# )

# # Build Mail Groups

# # Imports and Status
# # MailGroup.create(name: "Last Footprints Uploaded for the Day", description: "Notifies group when a user checks the box on the Footprint Import that the last Footprints are being uploaded for the day")
# MailGroup.create(name: "Footprints", description: "Notifies group when someone Uploads a Footprint Shapefile")
# MailGroup.create(name: "Photo Index", description: "Notifies group when someone Uploads a Photo Index File")
# MailGroup.create(name: "AT Done", description: "Notifies the group when the EO is imported and the associated Tiles are marked as AT Done.")
# MailGroup.create(name: "Ortho Processing", description: "Notifies group when the Cutfile is created and the Ortho Processing has been set to Tiles")
# MailGroup.create(name: "Tile Dump", description: "Notifies group when the Tile Dump has been completed")
# MailGroup.create(name: "Final Delivery", description: "Notifies group when the Final Delivery has been completed")
# MailGroup.create(name: "USDA Approved", description: "Notifies group when someone updates a packing slip that it has been accepted by the USDA and can be invoiced.")
# MailGroup.create(name: "Excel Export", description: "Notifies the group when someone exports the Excel report.")
# MailGroup.create(name: "EAWS", description: "Notifies the group when imports/exports related to the Early Access Web Services are generated.")

# # Daily
# MailGroup.create(name: "Daily Progress Report", description: "Sends an email when the Daily Progress report has been completed or if there is any Reports that are overdue.")
# MailGroup.create(name: "Ready to Ship", description: "Daily reminder of what Tiles are ready to ship sent at 8AM. If no Tiles are ready then it will confirm in the email.")

# # Rejections and Coverages
# MailGroup.create(name: "Easements with Multiple Coverages", description: "Notifies the group when the system checks that an Easement is covered by multiple Footprints of different flight dates or is unrejected and there are Footprints that cover it.")
# MailGroup.create(name: "Rejection", description: "Email is sent when a Tile has been rejected, either manually or automatically with the Photo Index or Frame Center Imports.")

# # Sanity
# MailGroup.create(name: "Email Relay Check", description: "Daily Email that's only purpose is to verify the email relay is working")

# # Daily audit check
# MailGroup.create(name: "Audit", description: "Email is sent during the Quick or Nightly Audits to notify of potential errors within the application.")
# MailGroup.create(name: "Errors", description: "Group is notified when critical errors are found due to crashes or catches.")

# if Rails.env.development?
#     # add admin to mailgroups
#     MailGroup.all.each { |mg| mg.users << admin }
# else
#     mg = MailGroup.find_by(name: "AT Done")
#     Rails.application.secrets.at_done_users.each {|obj| mg.users << User.find_by(obj) }

#     mg = MailGroup.find_by(name: "Ready to Ship")
#     Rails.application.secrets.ready_to_ship_users.each {|obj| mg.users << User.find_by(obj) }

#     mg = MailGroup.find_by(name: "Rejection")
#     Rails.application.secrets.rejection_users.each {|obj| mg.users << User.find_by(obj) }

#     mg = MailGroup.find_by(name: "Errors")
#     Rails.application.secrets.error_users.each {|obj| mg.users << User.find_by(obj) }

#     mg = MailGroup.find_by(name: "USDA Approved")
#     Rails.application.secrets.usda_approved_users.each {|obj| mg.users << User.find_by(obj) }

#     mg = MailGroup.find_by(name: "Audit")
#     Rails.application.secrets.audit_users.each {|obj| mg.users << User.find_by(obj) }

#     mg = MailGroup.find_by(name: "Final Delivery")
#     Rails.application.secrets.packing_slip.each {|obj| mg.users << User.find_by(obj) }

#     mg = MailGroup.find_by(name: "Photo Index")
#     Rails.application.secrets.photo_index.each {|obj| mg.users << User.find_by(obj) }
# end

# # -----------------------------

# # Upload Shapefiles
# require 'rgeo/shapefile'

# # Import the States
# RGeo::Shapefile::Reader.open("#{Rails.application.secrets.state_path}") do |file|
#     # puts "File contains #{file.num_records} records."
#     p "States"
#     p "--------------------"
#     file.each do |record|

#         # p "------------"
#         # p "checking: #{record.attributes["STUSPS"]}"
#         # p Rails.application.secrets.active_states.include?(record.attributes["STUSPS"])
#         # p State.find_by(abv: record.attributes["STUSPS"]).nil?

#         active_sl_states = Rails.application.secrets.active_sl_states || []
#         active_nri_states = Rails.application.secrets.active_nri_states || []

#         # if Rails.application.secrets.active_sl_states.include?(record.attributes["STUSPS"]) && State.find_by(abv: record.attributes["STUSPS"]).nil? || Rails.application.secrets.active_naip_states.include?(record.attributes["STUSPS"]) && State.find_by(abv: record.attributes["STUSPS"]).nil?
#         if (active_sl_states.include?(record.attributes["STUSPS"]) || active_nri_states.include?(record.attributes["STUSPS"]) ) && State.find_by(abv: record.attributes["STUSPS"]).nil? 

#             puts "MATCH: #{record.attributes["STUSPS"]}"
#             # puts "Record number #{record.index}:"
#             # puts "  Geometry: #{record.geometry.as_text}"
#             # puts "  Attributes: #{record.attributes.inspect}"
#             State.create(
#                 fips: record.attributes["STATEFP"].strip,
#                 abv: record.attributes["STUSPS"].strip,
#                 name: record.attributes["NAME"].strip,
#                 geom: record.geometry
#             )
#         end
#     end
# end

# # # Import the Counties
# RGeo::Shapefile::Reader.open("#{Rails.application.secrets.county_path}", encoding: 'ISO-8859-1') do |file|
#     # puts "File contains #{file.num_records} records."
#     p "Counties"
#     p "--------------------"

#     file.each do |record|

#         state = State.find_by(fips: record.attributes["STATEFP"])

#         if state.present? && state.easements.count == 0

#             puts "Matched #{state.name} - Record number #{record.index}:"
#             # puts "  Geometry: #{record.geometry.as_text}"
#             # puts "  Attributes: #{record.attributes.inspect}"
#             # state = State.where(fips: record.attributes["STATEFP"]).first
#             state.counties.create(
#                 fips: record.attributes["COUNTYFP"].strip,
#                 full_fips: record.attributes["GEOID"].strip,
#                 name: record.attributes["NAME"].strip,
#                 geom: record.geometry
#             )
#         end
#     end
# end

# # Import the UTM
# RGeo::Shapefile::Reader.open("#{Rails.application.secrets.utm_path}") do |file|
#     # puts "File contains #{file.num_records} records."
#     p "UTM"
#     p "--------------------"
#     file.each do |record|
#         p "++++++++++++"
#         puts "Record number #{record.index}:"
#         # puts "  Geometry: #{record.geometry.as_text}"
#         # puts "  Attributes: #{record.attributes.inspect}"

#         p !(0..20).to_a.include?(record.attributes["ZONE"].to_i)
#         p Utm.find_by(zone: record.attributes["ZONE"]).present?
#         p "++++++++++++"

#         next if !(0..20).to_a.include?(record.attributes["ZONE"].to_i)
#         next if Utm.find_by(zone: record.attributes["ZONE"]).present?

#         # puts "Record number #{record.index}:"

#         Utm.create(
#             # swlon: record.attributes["swlon"],
#             # swlat: record.attributes["swlat"],
#             hemisphere: "N",
#             zone: record.attributes["ZONE"],
#             geom: record.geometry
#         )
#     end
# end


# # Import the Timezone
# RGeo::Shapefile::Reader.open("#{Rails.application.secrets.timezone_path}") do |file|
#     # puts "File contains #{file.num_records} records."
#     p "TimeZone"
#     p "--------------------"
#     file.each do |record|
#         # p "++++++++++++"
#         puts "Timezone #{record.attributes["TZID"]}"

#         TimeZone.create(
#             name: record.attributes["TZID"].strip,
#             geom: record.geometry
#         )
#     end
# end


# RGeo::Shapefile::Reader.open(
#   "/media/sf_SharedFolder/2026/boundaries/dissolved_pr/dissolved_pr.shp"
# ) do |file|
#   file.each do |record|
#     new_geom_wkt = record.geometry.as_text.gsub(/\s+/, ' ').strip.gsub("'", "''")

#     ActiveRecord::Base.connection.execute(<<~SQL)
#       UPDATE counties
#       SET geom = ST_Multi(ST_Union(geom::geometry, ST_GeomFromText('#{new_geom_wkt}', 4326)))::geography
#       WHERE id = 849;
#     SQL

#     ActiveRecord::Base.connection.execute(<<~SQL)
#       UPDATE states
#       SET geom = ST_Multi(ST_Union(geom::geometry, ST_GeomFromText('#{new_geom_wkt}', 4326)))::geography
#       WHERE id = 28;
#     SQL
#   end
# end