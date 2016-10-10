require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]

opts = {
  path: '/chattanooga-police-incidents',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.chattlibrary.org/resource/jstk-5mri.json?' + Rack::Utils.build_query({
    '$order' => 'date_incident DESC',
    '$limit' => 1000,
    '$where' => <<-WHERE.oneline
      incident_description != 'Misc Report'
      AND latitude IS NOT NULL
      AND longitude IS NOT NULL
      AND date_incident >= '#{7.days.ago.strftime("%Y-%m-%dT%H:%M:%S")}'
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |record|
    title = "Police incident number #{record['case_number']} occurred near #{record['address']}. The incident type is '#{record['incident_description']}'."
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