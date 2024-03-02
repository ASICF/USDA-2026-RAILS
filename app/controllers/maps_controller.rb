class MapsController < ApplicationController
    authorize_resource :tiles

    def fetch
        p params[:poly_id]

        render json: Map.build(params[:poly_id])

    end

    def easement
        easement = Easement.find_by(poly_id: params[:poly_id])

        if easement.nil? 
            render json: {
                "type": "FeatureCollection",
                "features": []
            }
        else 
            # Generage Easement GeoJSON
            factory = RGeo::GeoJSON::EntityFactory.instance
            features = [factory.feature(easement.geom, easement.id, easement.attributes.except("geom"))]
            collection = RGeo::GeoJSON.encode(factory.feature_collection(features))
            factory = nil

            render json: collection
        end
    end

    def tile
        tile = Tile.find_by(poly_id: params[:poly_id])

        if tile.nil? 
            render json: {
                "type": "FeatureCollection",
                "features": []
            }
        else 
            # Generage Tile GeoJSON
            factory = RGeo::GeoJSON::EntityFactory.instance
            features = [factory.feature(tile.geom, tile.id, tile.attributes.except("geom"))]
            collection = RGeo::GeoJSON.encode(factory.feature_collection(features))
            factory = nil

            render json: collection
        end
    end

    def footprints
        tile = Tile.find_by(poly_id: params[:poly_id])

        if tile.nil? 
            render json: {
                "type": "FeatureCollection",
                "features": []
            }
        else 
            # footprints = Footprint.joins("INNER JOIN tiles ON tiles.poly_id='#{params[:poly_id]}' AND st_intersects(footprints.geom::geometry, tiles.geom::geometry)")
            footprints = tile.footprints

            features = []
            factory = RGeo::GeoJSON::EntityFactory.instance
            footprints.each do |record|
                features << factory.feature(record.geom, record.id, record.attributes.except("geom"))
            end
            collection = RGeo::GeoJSON.encode(factory.feature_collection(features))
            factory = nil

            render json: collection
        end
    end

    def ads
        # tile = Tile.find_by(poly_id: params[:poly_id])

        # if tile.nil? 
            render json: {
                "type": "FeatureCollection",
                "features": []
            }
        # else 
        #     ads = AirborneDigitalSensor.joins("INNER JOIN tiles ON tiles.poly_id='#{params[:poly_id]}' AND st_intersects(tiles.geom::geometry, airborne_digital_sensors.geom::geometry)")

        #     features = []
        #     factory = RGeo::GeoJSON::EntityFactory.instance
        #     ads.each do |record|
        #         features << factory.feature(record.geom, record.id, record.attributes.except("geom"))
        #     end
        #     collection = RGeo::GeoJSON.encode(factory.feature_collection(features))
        #     factory = nil

        #     render json: collection
        # end
    end

    def frame_centers

        tile = Tile.find_by(poly_id: params[:poly_id])

        if tile.nil? 
            render json: {
                "type": "FeatureCollection",
                "features": []
            }
        else 
            frame_centers = FrameCenter.joins("INNER JOIN tiles ON tiles.poly_id='#{params[:poly_id]}' AND st_contains(tiles.geom::geometry, frame_centers.geom::geometry)")
            frame_centers = []
            tile.footprints.each do |footprint|
                frame_centers << footprint.frame_center if footprint.frame_center.present?
            end
    
            features = []
            factory = RGeo::GeoJSON::EntityFactory.instance
            frame_centers.each do |record|
                features << factory.feature(record.geom, record.id, record.attributes.except("geom"))
            end
            collection = RGeo::GeoJSON.encode(factory.feature_collection(features))
            factory = nil
    
            render json: collection
        end

    end

end