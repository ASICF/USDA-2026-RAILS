class FinalDeliverySplits

    def self.preprocessing input_directory='P:\Vol_1\Bernard_Test', packing_slip=PackingSlip.find(144)

        output = {
            count: 0,
            pass: false,
            errors: []
        }
        unmatched_tiles = []
        verified_splits = []

        # get the packing slip project and state
        project = packing_slip.project
        state = packing_slip.state
        psn = packing_slip.name

        # convert the path to unix pathing
        unix_path = Task.build input_directory
        split_folder = "#{unix_path}/Big_Tiles"
        final_delivery_folder = "#{unix_path}/Final_Delivery_#{psn}"

        # Check the user supplied path
        # => Make sure it's all scoped under the project folder
        # => Check if the Big Tiles folder exists

        if !File.directory?(split_folder)

            # => Create the Big Tiles folder if it doesn't exist
            FileUtils.mkdir_p(split_folder)

            # => If no Big Tile then just cancel the process
            output[:message] = "No splits found in #{split_folder}"
            output[:pass] = false

            return output
        end

        if !File.directory?(final_delivery_folder)

            # => Create the Big Tiles folder if it doesn't exist
            FileUtils.mkdir_p(split_folder)

            # => If no Big Tile then just cancel the process
            output[:message] = "No splits found in #{split_folder}"
            output[:pass] = false

            return output
        end


        # iterate the tiffs in the folder
        Dir.glob("#{split_folder}/*.tif").each do |file|
            # p file

            filename = File.basename(file)
            filename_without_extension = File.basename(file, '.tif')

            # extract the 
            parsed_poly_id = FinalDeliverySplits.extract_id filename_without_extension, project

            # p "-------"
            # p parsed_poly_id
            
            # find the tile based on the state, project, parsed poly id and packing slip
            tile = state.tiles.find_by(poly_id: parsed_poly_id[:poly_id], project: project, packing_slip: packing_slip)

            if tile.present?

                # p "#{final_delivery_folder}/#{project}/#{tile.state_abv}/#{tile.county.full_fips}/Orthos/#{tile.filename}.tif"

                # check if the tile is in the final delivery folder
                if File.file?("#{final_delivery_folder}/#{project}/#{tile.state_abv}/#{tile.county.full_fips}/Orthos/#{tile.filename}.tif")

                    # check the tif bands to make sure they are valid
                    gdalinfo_response = `gdalinfo "#{file_path}/#{filename_without_extension}.tif"`

                    if gdalinfo_response.include? "Band 4"  
                        verified_splits << "#{split_folder}/#{filename}"
                    else
                        output[:errors] << "#{filename} Does Not have 4th Band"
                    end
                end

                # check if the file exsts in the packing slip final delivery folder

            else
                # check if the tile exists in the app
                tile = Tile.find_by(poly_id: parsed_poly_id[:poly_id])

                if !tile.present? 

                    # Add to the unmatched tiles that the filename was not found in the app
                    # => Send email after validation process notifying user
                    unmatched_tiles << filename
                end
            end

        end

        p " "
        p "Verified Splits"
        p "--------------"
        pp verified_splits

        p " "
        p "Unmatched Tiles"
        p "--------------"
        p unmatched_tiles

        # Check the imagery for bands and projection
    end

    def self.extract_id filename="ortho_AL_15_7341010700H6BB000c_20240820", project="SL"
        # takes a filename of a split and return the polyid

        result = {
            poly_id: nil,
            split_poly_id: nil,
        }

        arr = filename.split("_")

        if project === "SL"
            # the first three indices should be "Ortho", state abv, and "15" so skip those
            modified_arr = arr.drop(3)

            # Remove the last index which is the date
            modified_arr.pop(1)

            # Result should be the poly_id and the split index (if it exists)
            if modified_arr.length > 1
                # return modified_arr.join("_")
                result[:poly_id] = modified_arr[0]
                result[:split_poly_id] = modified_arr.join("_")
            else
                # return modified_arr[0]
                result[:poly_id] = modified_arr[0]
                result[:split_poly_id] = modified_arr[0]
            end
        end

        return result
    end

    def self.processing
        # Create the folder structure 
        # => OriginalSplit
        # => ToDelete
        # => ToMove

        # Iterate the Big Tiles folder Tiffs and extract the poliyid to check against the database
        # => IMPORTANT! Production should add the _1, _2 to the end of the file instead of after the PolyID for better parsing 
        # => Check against the database to find the Packing Slip info
        # => check if associated tiff is in the ToDelete folder then the final delivery folder
        # => If match then copy the .tif and .tfw to the OriginalSplit folder
        # => Move the associated .tiff, .tfw, and .xml files from the Final Delivery to the ToDelete folder
        # ==> Track the folder paths in a text file so that it can be referenced when moving files back by the app or manually. 

        # Copy the XML from the ToDelete Folder into the ToMove folder
        # Update the filename of the xml to match the split filename
        # => Update the contents of the file with the new PolyID

        # Update the TiffTags to reference the new PolyID

        # once complete run the Migration
        # => Keep this separate from the migration process in case it fails it will be easier to move them back and forth
    end

    def self.migration
        # Iterate the county Folders in the ToMove folder into the County folder of the Final Delivery

        # build the Tile Index once completed
    end

    def self.build_tile_index
        # Connect to the Final Delivery build tile index method
    end

    def self.validation
        # Pass to the Final Delivery Validation
    end

    def self.cleanup
        # Runs if the script fails
        # => Copy the original tile from the ToDelete to it's county folder in the Final Delivery
        # => Copy the split tiles from OriginalSplit into the Big Tiles folder
    end

end