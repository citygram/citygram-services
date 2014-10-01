require 'spy_glass/registry'

opts = {
  path: '/clt-certificate-of-occupancy',
  cache: SpyGlass::Cache::Memory.new(expires_in: 600),
  source: 'http://cfa.mecklenburgcountync.gov/api/occupancy',
}

SpyGlass::Registry << SpyGlass::Client::Meck.new(opts) do |collection|
  features = collection.map do |record|
    x_coord = record['xcoord']
    y_coord = record['ycoord']

    next unless x_coord && y_coord
    next unless x_coord != 0 || y_coord != 0

    title = <<-TITLE.oneline
      A Certificate of Occupancy has been 
    TITLE

    lon, lat = SpyGlass::Utils.point_srid_transform(x_coord, y_coord, 3359, 4326)

    {
      # 'id' => nil,
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [lon,lat]
      },
      'properties' => record.merge('title' => title)
    }
  end

  { 'type' => 'FeatureCollection', 'features' => features.compact }
end
