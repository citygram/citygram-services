require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Mountain Time (US & Canada)"]

opts = {
  path: '/edmonton-bylaw-infractions',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.edmonton.ca/resource/eunm-re6n?' + Rack::Utils.build_query({
    '$order' => 'REPORT_PERIOD DESC',
    '$limit' => 10,
    '$where' => " latitude IS NOT NULL" +
                " AND longitude IS NOT NULL"
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |record|
	title = "A #{record['COMPLAINT']} bylaw infraction was initiated by a #{record['INITIATIED_BY']} on #{record['REPORT_PERIOD']}. It's status is #{record['STATUS']}."
      {
        'COMPLAIN'=> record['COMPLAINT'],
		'REPORT_PERIOD'=> record['REPORT_PERIOD],
		'STATUS'=> record['STATUS'],
        'type'=> 'Feature',
        'properties' => record.merge('title' => title),
        'INITIATIED_BY' => record['INITIATIED_BY'],
        'geometry' => {
          'type' => 'Point',
          'coordinates' => [
            record['LONGITUDE'].to_f,
            record['LATITUDE'].to_f
          ]
        }
      }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
