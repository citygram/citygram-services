require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Mountain Time (US & Canada)"]

opts = {
  path: '/edmonton-building-permits.rb',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.edmonton.ca/resource/rwuh-apwg.json' + Rack::Utils.build_query({
    '$order' => 'permit_date DESC',
    '$limit' => 10,
    '$where' => " latitude IS NOT NULL" +
                " AND longitude IS NOT NULL"
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |record|
    title = "Permit number #{record['permit_number']} has been issued on #{record['issue_date']} for #{record['address']}. This is a #{record['job_category']} permit."
      {
        'id'=> record['permit_number'],
        'type'=> 'Feature',
        'properties' => record.merge('title' => title),
        'job_description' => record['job_description'],
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
