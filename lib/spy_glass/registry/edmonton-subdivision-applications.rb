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
        title = "A subdivision is in review at #{record['address']} as City File # #{record['filenumber']}."
    else
        title = "A subdivision has been approved at #{record['address']} as City File # #{record['filenumber']}."  
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
