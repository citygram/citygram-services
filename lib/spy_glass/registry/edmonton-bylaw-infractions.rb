require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Mountain Time (US & Canada)"]

opts = {
  path: '/edmonton-bylaw-infractions',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.edmonton.ca/resource/eunm-re6n?' + Rack::Utils.build_query({
    '$order' => 'REPORT_PERIOD DESC',
    '$limit' => 10,
    '$where' => " latitude IS NOT NULL" +
                " AND longitude IS NOT NULL" +
                " AND complaint IS NOT NULL"
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |record|
	title = "A #{record["complaint"]} bylaw infraction was initiated by a #{record['initiated_by']} on #{record['report_period']}. It's status is #{record['status']}."
      {
        'COMPLAIN'=> record['complaint'],
		'REPORT_PERIOD'=> record['report_period'],
		'STATUS'=> record['status'],
        'type'=> 'Feature',
        'properties' => record.merge('title' => title),
        'INITIATIED_BY' => record['initiated_by'],
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