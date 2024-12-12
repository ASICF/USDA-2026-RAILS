class BufferedTile < ApplicationRecord

    def self.export state_abv="GA", output_path="/vol1/bernard_test/2024/SL/buff_tiles_test/"

        p "++++++++++"
        p "TACO"
        p state_abv
        p output_path
        p "++++++++++"

        # Get the folder name by converting the current time to seconds
        folder = Time.now.to_i

        path = "#{Rails.root}/assets/eo_splitter_shapefile/#{folder}"

        # Create a folder if it doesn't exist
        FileUtils.mkdir_p("#{path}") unless File.directory?(path)
        FileUtils.mkdir_p("#{path}/json")
        FileUtils.mkdir_p("#{path}/shapefile")
        FileUtils.mkdir_p("#{path}/zipped")

        # Set the file name
        file_name = "buffered_tiles_#{state_abv}"

        # create Shapefile
        factory = RGeo::GeoJSON::EntityFactory.instance
        features = Array.new

        # filters the buffered_tiles by state_abv
        BufferedTile.where(state_abv: state_abv).each do |record|

            obj = {
                poly_id: record.poly_id,
                filename: record.filename,
                state_abv: record.state_abv
            }

            features << factory.feature(record.geom, record.id, obj)

        end

        p "#{path}/json/#{file_name}.json"

        # Creates a text file and saves it to the report directory
        File.open("#{path}/json/#{file_name}.json", "w+") do |f|
            f.puts(RGeo::GeoJSON.encode(factory.feature_collection(features)).to_json)
        end

        # Convert GeoJSON to Shapefile with ogr2ogr
        `ogr2ogr -f "ESRI Shapefile" -fieldTypeToString Date,Time #{path}/shapefile/#{file_name}.shp "#{path}/json/#{file_name}.json"`

        [".shp", ".shx", ".dbf", ".prj"].each do |ext|
            FileUtils.cp("#{path}/shapefile/#{file_name}#{ext}", "#{output_path}/#{file_name}#{ext}")

            # p "#{path}/shapefile/#{file_name}#{ext}"
            # p "#{output_path}/#{file_name}#{ext}"
            # p "-----------------"
        end

        # # Zip the files
        # Zip::File.open("#{path}/zipped/#{file_name}.zip", Zip::File::CREATE) do |zipfile|
        #     [".shp", ".shx", ".dbf", ".prj"].each do |ext|
        #         zipfile.add("#{file_name}#{ext}", File.join("#{path}/shapefile/", "#{file_name}#{ext}"))
        #     end
        # end

        # save to output path
        # FileUtils.cp("#{path}/zipped/#{file_name}.zip", "#{output_path}/#{file_name}.zip")

    end

end
