class Map

    def self.build poly_id

        easement = Easement.find_by(poly_id: poly_id)

        if easement.nil?
            return {
                state: false,
                message: "Could not find Easement with PolyID of #{poly_id}"
            }
        end

        return {
            state: true,
            center: [easement.latitude, easement.longitude],
            easement: Map.build_easement(poly_id),
            tile: Map.build_tile(poly_id),
            footprints: Map.build_footprints(poly_id),
            frame_centers: Map.build_frame_centers(poly_id),
            photo_indices: Map.build_photo_indices(poly_id),
        }

    end

    private

    def self.build_easement poly_id
        easement = Easement.find_by(poly_id: poly_id)

        if easement.nil? 
            return {
                "type": "FeatureCollection",
                "features": []
            }
        else 
            # Generage Easement GeoJSON
            factory = RGeo::GeoJSON::EntityFactory.instance
            features = [factory.feature(easement.geom, easement.id, easement.attributes.except("geom"))]
            collection = RGeo::GeoJSON.encode(factory.feature_collection(features))
            p "___"
            p collection
            factory = nil

            return collection
        end
    end

    def self.build_tile poly_id
        tile = Tile.find_by(poly_id: poly_id)

        if tile.nil? 
            return {
                "type": "FeatureCollection",
                "features": []
            }
        else 
            # Generage Tile GeoJSON
            factory = RGeo::GeoJSON::EntityFactory.instance
            features = [factory.feature(tile.geom, tile.id, tile.attributes.except("geom"))]
            collection = RGeo::GeoJSON.encode(factory.feature_collection(features))
            factory = nil

            return collection
        end
    end

    def self.build_footprints poly_id
        tile = Tile.find_by(poly_id: poly_id)

        if tile.nil? 
            return {
                "type": "FeatureCollection",
                "features": []
            }
        else 
            # footprints = Footprint.joins("INNER JOIN tiles ON tiles.poly_id='#{poly_id}' AND st_intersects(footprints.geom::geometry, tiles.geom::geometry)")
            footprints = tile.footprints

            features = []
            factory = RGeo::GeoJSON::EntityFactory.instance
            footprints.each do |record|
                features << factory.feature(record.geom, record.id, record.attributes.except("geom"))
            end
            collection = RGeo::GeoJSON.encode(factory.feature_collection(features))
            factory = nil

            return collection
        end
    end

    def self.build_frame_centers poly_id
        tile = Tile.find_by(poly_id: poly_id)

        if tile.nil? 
            return {
                "type": "FeatureCollection",
                "features": []
            }
        else 
            frame_centers = FrameCenter.where(footprint_id: tile.footprints.pluck(:id))
    
            features = []
            factory = RGeo::GeoJSON::EntityFactory.instance
            frame_centers.each do |record|
                features << factory.feature(record.geom, record.id, record.attributes.except("geom"))
            end
            collection = RGeo::GeoJSON.encode(factory.feature_collection(features))
            factory = nil
    
            return collection
        end
    end

    def self.build_photo_indices poly_id
        tile = Tile.find_by(poly_id: poly_id)

        if tile.nil? 
            return {
                "type": "FeatureCollection",
                "features": []
            }
        else 
            photo_indices = PhotoIndex.where(footprint_id: tile.footprints.pluck(:id))
    
            features = []
            factory = RGeo::GeoJSON::EntityFactory.instance
            photo_indices.each do |record|
                features << factory.feature(record.geom, record.id, record.attributes.except("geom"))
            end
            collection = RGeo::GeoJSON.encode(factory.feature_collection(features))
            factory = nil
    
            return collection
        end
    end

end