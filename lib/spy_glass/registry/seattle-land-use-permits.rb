require 'spy_glass/registry'

opts = {
  path: '/seattle-land-use-permits',
  cache: SpyGlass::Cache::Memory.new(expires_in: 3600),
  source: 'http://data.seattle.gov/resource/uyyd-8gak?'+Rack::Utils.build_query({
    '$limit' => 100,
    '$order' => 'application_date DESC',
    '$where' => <<-WHERE.oneline
      status = 'Application Accepted' AND
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      category IS NOT NULL AND
      application_date IS NOT NULL AND
      application_permit_number IS NOT NULL AND
      permit_type IS NOT NULL AND
      address IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE.oneline
      #{SpyGlass::Salutations.next} A #{item['category'].downcase} land use permit near you at #{item['address']} has been filed.
      Find out more at #{item['permit_and_complaint_status_url']['url']}.
    TITLE

    {
      'id' => item['application_permit_number'],
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

