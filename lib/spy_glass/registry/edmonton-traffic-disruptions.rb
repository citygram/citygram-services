require 'spy_glass/registry'
require "base64"

time_zone = ActiveSupport::TimeZone["Mountain Time (US & Canada)"]

opts = {
  path: '/edmonton-traffic-disruptions',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.edmonton.ca/resource/87ck-293k.json?' + Rack::Utils.build_query({
    '$order' => 'starting_date DESC',
    '$limit' => 100,
    '$where' => "location IS NOT NULL"
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |record|
    title = "#{record['details']}."
      {
        'id'=> Base64.encode64(record['details']),
        'type'=> 'Feature',
        'properties' => record.merge('title' => title),
        'geometry' => {
          'type' => 'Point',
          'coordinates' => [
            record['location']['longitude'].to_f,
            record['location']['latitude'].to_f
          ]
        }
      }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
