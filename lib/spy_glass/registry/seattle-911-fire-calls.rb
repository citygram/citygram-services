require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Pacific Time (US & Canada)"]

opts = {
  path: '/seattle-911-fire-calls',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://data.seattle.gov/resource/kzjm-xkqj?'+Rack::Utils.build_query({
    '$limit' => 100,
    '$order' => 'datetime DESC',
    '$where' => <<-WHERE.oneline
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      datetime IS NOT NULL AND
      incident_number IS NOT NULL AND
      type IS NOT NULL AND
      address IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    time = Time.at(item['datetime']).in_time_zone(time_zone)
    title = <<-TITLE.oneline
      Seattle Fire Department was dispatched to #{item['address']} at around #{time.strftime('%I:%M%P')}.
      The event was categorized as "#{item['type'].downcase}".
    TITLE

    {
      'id' => item['incident_number'],
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

