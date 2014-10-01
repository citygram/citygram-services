require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]

opts = {
  path: '/nyc-311',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://data.cityofnewyork.us/resource/erm2-nwe9.json?'+Rack::Utils.build_query({
    '$limit' => 1000,
    '$order' => 'created_date DESC',
    '$where' => <<-WHERE.oneline
      created_date >= '#{7.days.ago.iso8601}' AND
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      unique_key IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    time = Time.iso8601(item['created_date']).in_time_zone(time_zone)
    title =  <<-TITLE.oneline
      A new 311 case has been opened at #{item['incident_address']} in #{item['city']}.
      The complaint type is #{item['complaint_type'].downcase} - #{item['descriptor']} and the assigned agency is #{item['agency']}
    TITLE

    {
      'id' => item['unique_key'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['longitude'].to_f,
          item['latitude'].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end

