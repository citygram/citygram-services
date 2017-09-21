require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Mountain Time (US & Canada)"]

opts = {
  path: '/edmonton-traffic-disruptions.rb',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.edmonton.ca/resource/ju4q-wijd.json' + Rack::Utils.build_query({
    '$order' => 'starting_date DESC',
    '$limit' => 10,
    '$where' => " location IS NOT NULL"
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  puts("collection: #{collection}")
  features = collection.map do |record|
    title = "#{record['details']}."
      {
        'id'=> record['disruption_number'],
        'type'=> 'Feature',
        'properties' => record.merge('title' => title),
        'geometry' => record['location']
      }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
