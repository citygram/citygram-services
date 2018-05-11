require 'spy_glass/registry'

# code reuse from edmonton-building-permits.rb, to be modified when dev permit dataset is available

time_zone = ActiveSupport::TimeZone["Mountain Time (US & Canada)"]

opts = {
  path: '/edmonton-development-permits',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.edmonton.ca/resource/rwuh-apwg?' + Rack::Utils.build_query({ # TODO: change to dev permit dataset when available
    '$order' => 'permit_date DESC',
    '$limit' => 10,
    '$where' => " latitude IS NOT NULL" +
                " AND longitude IS NOT NULL"
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |record|
    # TODO: possibly modify
    title = "A development permit #{record['permit_class']} was approved on #{record['issue_date']} at #{record['address']} as City File # #{record['permit_number']} . #{record['job_description']}."
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
