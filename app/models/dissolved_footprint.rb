class DissolvedFootprint < ApplicationRecord
    include Concerns::Archive

    # Gets all the geometry of the footprints and creates a single layer
    def self.dissolve_by_flight_date flight_date, project

        # Find or create the dissolved layer and update the geom to be nil
        DissolvedFootprint.find_or_create_by(name: "flight_date").update(geom: nil)

        # Dissolve the footprints 
        sql = "UPDATE dissolved_footprints SET geom = (SELECT ST_Multi(st_union(ST_Multi(geom::geometry))) AS the_geom from footprints 
        where ST_IsValid(geom::geometry) AND footprints.project = '#{project}' AND footprints.flight_date = '#{Date.parse(flight_date).strftime("%F")}') 
        where name='flight_date'"
        ActiveRecord::Base.connection.execute(sql)
    end

    # Gets all the geometry of the footprints and creates a single layer
    def self.dissolve_by_flight_date_and_project_state flight_date, state_id, project

        # Find or create the dissolved layer and update the geom to be nil
        DissolvedFootprint.find_or_create_by(name: "flight_date").update(geom: nil)

        # Dissolve the footprints 
        sql = "UPDATE dissolved_footprints SET geom = (SELECT ST_Multi(st_union(ST_Multi(geom::geometry))) AS the_geom from footprints 
        where ST_IsValid(geom::geometry) AND footprints.project = '#{project}'
        AND footprints.flight_date = '#{Date.parse(flight_date).strftime("%F")}' AND footprints.project_state_id = #{state_id}) where name='flight_date'"
        ActiveRecord::Base.connection.execute(sql)
    end

    def self.dissolve_by_scope flight_date, flown_by_id, camera_id, project

        # Find or create the dissolved layer and update the geom to be nil
        DissolvedFootprint.find_or_create_by(name: "scoped").update(geom: nil)

        sql = "UPDATE dissolved_footprints SET geom = (SELECT ST_Multi(st_union(ST_Multi(geom::geometry))) AS the_geom from footprints where ST_IsValid(geom::geometry) AND footprints.project = '#{project}' AND footprints.flight_date = '#{Date.parse(flight_date).strftime("%F")}' AND footprints.flown_by_id = #{flown_by_id} AND footprints.camera_id = #{camera_id}) WHERE name='scoped'"
        ActiveRecord::Base.connection.execute(sql)
    end

    def self.by_upload upload, project

        raise StandardError.new "Dissolved Footprint Upload: No Footprints Detected in Upload" if upload.footprints.count == 0

        # Find or create the dissolved layer and update the geom to be nil
        DissolvedFootprint.find_or_create_by(name: "upload").update(geom: nil)

        sql = "UPDATE dissolved_footprints SET geom = (SELECT ST_Multi(st_union(ST_Multi(geom::geometry))) AS the_geom from footprints where ST_IsValid(geom::geometry) AND footprints.project = '#{project}' AND footprints.upload_id = '#{upload.id}') WHERE name='upload'"
        ActiveRecord::Base.connection.execute(sql)
    end

    def self.footprints footprint_ids, project

        raise StandardError.new "Dissolved Footprint: No Footprints supplied" if footprint_ids.count == 0

        # Find or create the dissolved layer and update the geom to be nil
        DissolvedFootprint.find_or_create_by(name: "footprints").update(geom: nil)

        sql = "UPDATE dissolved_footprints SET geom = (SELECT ST_Multi(st_union(ST_Multi(geom::geometry))) AS the_geom from footprints where ST_IsValid(geom::geometry) AND footprints.project = '#{project}' AND footprints.id IN (#{footprint_ids.join(", ")})) WHERE name='footprints'"
        ActiveRecord::Base.connection.execute(sql)

    end

    def self.doqqs doqq_ids

        raise StandardError.new "Dissolved Footprint: No Footprints supplied" if doqq_ids.count == 0

        # Find or create the dissolved layer and update the geom to be nil
        DissolvedFootprint.find_or_create_by(name: "doqqs").update(geom: nil)

        sql = "UPDATE dissolved_footprints SET geom = (SELECT ST_Multi(st_union(ST_Multi(geom::geometry))) AS the_geom from doqqs where ST_IsValid(geom::geometry) AND doqqs.id IN (#{doqq_ids.join(", ")})) WHERE name='doqqs'"
        ActiveRecord::Base.connection.execute(sql)

    end

    def self.destroy_dissolve_by_flight_date
        df = DissolvedFootprint.find_by(name: "flight_date")
        df.destroy if df.present?
    end

    def self.destroy_footprints
        df = DissolvedFootprint.find_by(name: "footprints")
        df.destroy if df.present?
    end

    def self.destroy
        DissolvedFootprint.destroy_all
    end
end
