require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Mountain Time (US & Canada)"]

opts = {
  path: '/edmonton-street-cleaning',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.edmonton.ca/resource/8j46-9qmc.json?' + Rack::Utils.build_query({
    '$order' => 'latest_scheduled_start_date DESC',
    '$limit' => 10,
    '$where' => " status = 'Scheduled' " +
                " AND location IS NOT NULL"
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |record|
    puts record.inspect
    start_date = DateTime.parse(record['earliest_scheduled_start_date']).in_time_zone(time_zone).strftime("%d/%m/%y")
    end_date = DateTime.parse(record['latest_scheduled_start_date']).in_time_zone(time_zone).strftime("%d/%m/%y")
    title = "Street cleaning for "+record['neighborhood_name']+ " will begin between #{start_date} and #{end_date}"
    
    #title = "Permit number #{record['permit_number']} has been issued on #{record['issue_date']} for #{record['address']}. This is a #{record['job_category']} permit."
      {
        'id'=> [ record['maintenance_area'], record['earliest_scheduled_start_date'] ].join('-'),
        'type'=> 'Feature',
        'properties' => record.merge('title' => title),
        'job_description' => record['job_description'],
        'geometry' => {
          'type' => 'Point',
          'coordinates' => record['location']['coordinates']
        }
      }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
