require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Mountain Time (US & Canada)"]

opts = {
  path: '/edmonton-subdivision-applications',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.edmonton.ca/resource/ezyy-ern8?' + Rack::Utils.build_query({
#    '$order' => 'permit_date DESC',
    '$limit' => 10,
    '$where' => " status == 'In Review'"
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |record|
    title = "#{record['legaldesc']} has been filed to recognize #{record['address']} as a subdivision within the #{record['nhood']} neighborhood."
      {
        'id'=> record['filenumber'],
        'type'=> 'Feature',
        'properties' => record.merge('title' => title),
        'geometry' => record['the_geom']
      }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
