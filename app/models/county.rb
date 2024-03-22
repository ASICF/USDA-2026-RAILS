class County < ApplicationRecord
    include Concerns::Archive

    # Associations
    belongs_to :state
    has_many :easements
    has_many :frame_centers
    has_many :tiles
    has_many :doqqs
    has_many :rejected_tiles

    # Scopes
    scope :active,          -> { where(id: Easement.pluck(:county_id).uniq).order(:name) }
    scope :active_sl,       -> { where(id: Easement.sl.pluck(:county_id).uniq).order(:name) }
    scope :active_nri,       -> { where(id: Easement.sl.pluck(:county_id).uniq).order(:name) }
    scope :sl_tiles_flown_but_not_shipped,  -> { where(id: Tile.sl.exclude_geom.county_flown.not_shipped.order(:county_name).pluck(:county_id).uniq)}
    scope :nri_tiles_flown_but_not_shipped,  -> { where(id: Tile.nri.exclude_geom.county_flown.not_shipped.order(:county_name).pluck(:county_id).uniq)}
    scope :exclude_geom,    -> { select( County.attribute_names - ['geom'] ) }

    # def self.copy_doqqs_to_county_folders

    #     path = "/vol2/226578_01_USDA_NJ_NAIP/03_FrameBase/Ortho_Raw/mosaic_180_GT_Final/ALL_new_outer/ALL_with_Burn_In/Brightened/"
    #     output = "CountyDoqqs/"
    #     # P:\Vol_2\226578_01_USDA_NJ_NAIP\03_FrameBase\Ortho_Raw\mosaic_180_GT_Final\ALL_new_outer\ALL_with_Burn_In\Brightened

    #     State.find(11).counties.each do |county|

    #         # get the doqqs that intersect
    #         doqqs = Doqq.where("st_intersects(doqqs.geom, ST_GeomFromText('#{county.geom.to_s}'))")

    #         p "County: #{county.name} : #{doqqs.count}"

    #         county_folder = "#{path}/#{output}/#{county.fips}"

    #         # Make the county folder
    #         FileUtils.mkdir_p(county_folder) unless File.directory?(county_folder)

    #         doqqs.each do |doqq|

    #             # if !File.file?("#{county_folder}/#{doqq.qq_apfo_name}.tif")
    #             #     p doqq.qq_apfo_name
    #             # end

    #             if File.file?("#{path}/#{doqq.qq_apfo_name}.tif")
    #                 p " - copying #{doqq.qq_apfo_name}"
    #                 FileUtils.cp("#{path}/#{doqq.qq_apfo_name}.tif", county_folder)
    #                 FileUtils.cp("#{path}/#{doqq.qq_apfo_name}.tfw", county_folder)
    #                 FileUtils.cp("#{path}/#{doqq.qq_apfo_name}.rdx", county_folder)
    #                 FileUtils.cp("#{path}/#{doqq.qq_apfo_name}.pyr", county_folder)
    #                 FileUtils.cp("#{path}/#{doqq.qq_apfo_name}.tif.xml", county_folder)
    #             else
    #                 p "#{doqq.qq_apfo_name} does not exist"
    #             end

    #         end

    #     end

    # end

    # def self.calculate_all_majority_flight_date_time

    #     arr = []
    #     State.find_by(abv: "NJ").counties.order(:fips).each do |county|
    #         fd = county.get_majority_flight_date_time

    #         arr << "#{county.fips} | #{fd}"
    #     end

    #     pp arr

    # end

    # def get_majority_flight_date_time

    #     p "-----------------"
    #     p self.name
    #     p self.full_fips
    #     # perform spatial query against the footprints since overlapping can be applicable
    #     # footprints = Footprint.select(:project, :flight_date_time).where(strip_frame: strip_frames).where("footprints.project = '#{project}' AND st_intersects(footprints.geom, ST_GeomFromText('#{self.geom.to_s}'))").where.not(flight_date_time: nil).order(:flight_date_time)

    #     p self.doqqs.count

    #     # footprints = self.footprints.exclude_geom.where(project: project)

    #     # p footprints.count

    #     dates = {}

    #     doqqs = Doqq.where("st_intersects(doqqs.geom, ST_GeomFromText('#{self.geom.to_s}'))")


    #     # p footprints.count
    #     # p footprints.naip.count
    #     doqqs.each do |doqq|

    #         # Format the date to easily associate it
    #         formatted = doqq.median_flight_date_time.strftime("%F")

    #         # Create a new empty value if the key doesn't exist
    #         dates[formatted] = 0 if dates[formatted].nil?

    #         # Add 1 to the value
    #         dates[formatted] += 1
    #     end

    #     p dates

    #     if !dates.blank?

    #         majority_flight_date = dates.max_by{|k,v| v}[0]

    #         p majority_flight_date
    #     end

    #     hours = {}
    #     flight_date_time_array = []

    #     # Now that there is a majority flight date (not time) then I need to get the 
    #     self.doqqs.where(flight_date: majority_flight_date).each do |doqq|

    #         next if doqq.median_flight_date_time.nil?

    #         # push to 
    #         flight_date_time_array << doqq.median_flight_date_time.to_f

    #     end

    #     p flight_date_time_array

    #     if flight_date_time_array.length > 0

    #         # Get the median Flight Date Time
    #         median = flight_date_time_array[flight_date_time_array.length / 2]

    #         return Time.at(median).strftime("%Y-%m-%dT%H:%M:%SZ")

    #         # # Average the flight date
    #         # self.median_flight_date_time = Time.at(median).utc
            
    #         # if !self.save
    #         #     raise Exception, "Could not calculat Median Flight Date Time for Tile: #{self.poly_id} | #{self.errors.full_messages.to_sentence}"
    #         # end

    #     else
    #         raise Exception, "Could not calculat Median Flight Date Time for Tile: #{self.poly_id}"
    #     end

    #     p "-----------------"

    # end

end
