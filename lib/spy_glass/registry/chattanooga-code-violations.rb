require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]

opts = {
  path: '/chattanooga-code-violations',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.chattlibrary.org/resource/qkb7-wdta.json?' + Rack::Utils.build_query({
    '$order' => 'date_entered DESC',
    '$limit' => 1000,
    '$where' => <<-WHERE.oneline
      status = 'Open'
      AND latitude IS NOT NULL
      AND longitude IS NOT NULL
      AND date_entered >= '#{7.days.ago.strftime("%Y-%m-%dT%H:%M:%S")}'
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |record|
    title = "Code violation number #{record['case_number']} has been created at #{record['street_number']} #{record['street_name']}. The violation type is '#{record['violation_description']}'."
    {
      'id' => record['case_number'],
      'type' => 'Feature',
      'properties' => record.merge('title' => title),
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          record['longitude'].to_f,
          record['latitude'].to_f
        ]
      }
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
