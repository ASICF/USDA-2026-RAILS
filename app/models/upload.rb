class Upload < ApplicationRecord
    include Concerns::Archive
    require 'zip'

    # Associations
    has_many :easements, dependent: :destroy
    has_many :footprints, dependent: :destroy
    has_many :rejected_footprints, dependent: :destroy
    has_many :tiles, dependent: :destroy
    has_many :doqqs, dependent: :destroy
    has_many :frame_centers, dependent: :destroy 
    has_many :rejected_frame_centers, dependent: :destroy 
    has_many :uptime_logs, dependent: :destroy 
    has_many :photo_indices, dependent: :destroy 
    has_many :historic_assocs, as: :historicable, dependent: :destroy
    has_many :histories, through: :historic_assocs
    belongs_to :uploader, class_name: 'User'

    # Scopes
    scope :easement_import, -> { where(upload_type: "Easement") }
    scope :tile_import, -> { where(upload_type: "Easement") }
    scope :footprint_import, -> { where(upload_type: "Footprint") }
    scope :frame_center_import, -> { where(upload_type: "FrameCenter") }

    def history
        histories.first
    end

    def zip_original
        # Check if there is an "original" folder inside the path
        # If so then check if a zipped file exists and return that
        # If not then zip the file and return the path

        # create an Error array to hold any messages
        output = {
            pass: false,
            file: nil,
            file_name: nil
        }

        if folder_path && File.directory?("#{folder_path}/original")
            if File.directory?("#{folder_path}/zipped")
                # Return the zipped file

                if Dir.glob("#{folder_path}/zipped/*.zip").count == 1
                    output[:pass] = true
                    output[:file] = Dir.glob("#{folder_path}/zipped/*.zip").first
                    output[:file_name] = File.basename(Dir.glob("#{folder_path}/zipped/*.zip").first)
                elsif Dir.glob("#{folder_path}/original/*.txt").count == 1
                    output[:pass] = true
                    output[:file] = Dir.glob("#{folder_path}/original/*.txt").first
                    output[:file_name] = File.basename(Dir.glob("#{folder_path}/original/*.txt").first)
                end

                return output
            else

                # Check if a shp or txt file
                if Dir.glob("#{folder_path}/original/*.shp").count > 0
                    # Make the zipped folder
                    FileUtils.mkdir_p("#{folder_path}/zipped")
                    # Find the shapefile 
                    files = Dir.glob("#{folder_path}/original/*.shp")
                elsif Dir.glob("#{folder_path}/original/*.txt").count == 1
                    # return the text file
                    output[:pass] = true
                    output[:file] = Dir.glob("#{folder_path}/original/*.txt").first
                    output[:file_name] = File.basename(Dir.glob("#{folder_path}/original/*.txt").first)
                    return output
                else
                    return output
                end

                # Zipped folder path
                zipped_path = "#{folder_path}/zipped/#{File.basename(files.first, ".shp")}.zip"

                # Zip the files
                Zip::File.open(zipped_path, Zip::File::CREATE) do |zipfile|
                    Dir[File.join("#{folder_path}/original", '*')].each do |file|
                        zipfile.add(file.sub("#{folder_path}/original/", ''), file)
                    end
                end

                output[:pass] = true
                output[:file] = zipped_path
                output[:file_name] = File.basename(zipped_path)
                return output
            end
        end

        return output
    end

end
