require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Mountain Time (US & Canada)"]

opts = {
  path: '/edmonton-development-permits',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.edmonton.ca/resource/8b78-2kux?' + Rack::Utils.build_query({ 
    '$order' => 'permit_date DESC',
    '$limit' => 10,
    '$where' => " permit_date IS NOT NULL" +
                " latitude IS NOT NULL" +
                " AND longitude IS NOT NULL"
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |record|
    title = "A development permit #{record['permit_class']} was approved on #{record['permit_date'].strftime('%m/%d/%Y')} at #{record['address']}. #{record['description_of_development']}."
      {
        'id'=> record['city_file_number'],
        'type'=> 'Feature',
        'properties' => record.merge('title' => title),
        'job_description' => record['description_of_development'],
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
