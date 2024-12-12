class FinalDeliverySplits

    def self.preprocessing
        # Check the user supplied path
        # => Check if the Big Tiles folder exists
        # => Create the Big Tiles folder if it doesn't exist
        # => If no Big Tile then just cancel the process

        # check the Big Tiles folder to see if there are any matches in the Final Delivery
        # Checks all the files required are found
        # Check the imagery for bands and projection
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