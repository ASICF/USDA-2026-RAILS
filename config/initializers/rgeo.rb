RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
    # By default, use the GEOS implementation for spatial columns.
    config.default = RGeo::Geos.factory_generator
  
    # But use a geographic implementation for polygon columns.
    config.register(RGeo::Geographic.spherical_factory(srid: 4326), geo_type: "multi_polygon")
end

# Causes GeoJson building to be hella slow
# => might need to be implemented in the future and have to work around it
# -----------------------------------------------------------------
# RGeo::ActiveRecord::SpatialFactoryStore.instance.tap do |config|
#     config.default = RGeo::Geographic.spherical_factory(srid: 4326)
# end