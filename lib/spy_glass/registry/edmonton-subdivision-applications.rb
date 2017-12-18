require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Mountain Time (US & Canada)"]

opts = {
  path: '/edmonton-subdivision-applications',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.edmonton.ca/resource/ezyy-ern8?' + Rack::Utils.build_query({
    '$order' => 'filenumber DESC',
    '$limit' => 20,
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |record|
    title = nil
    if record['status'] == "In Review"
       title = "Parcel(s) of land at #{record['address']} are currently in review for a subdivision application within the #{record['nhood']} neighborhood.  The file number is #{record['filenumber']} for #{record['legaldesc']}"
    else
       title = "Parcel(s) of land at #{record['address']} have been approved for a subdivision application within the #{record['nhood']} neighborhood.  The file number is #{record['filenumber']} for #{record['legaldesc']}"
    end
      {
        'id'=> record['filenumber'],
        'type'=> 'Feature',
        'properties' => record.merge('title' => title),
        'geometry' => record['the_geom']
      }
  end
  {'type' => 'FeatureCollection', 'features' => features}
end
