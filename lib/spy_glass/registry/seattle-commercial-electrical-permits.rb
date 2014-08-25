require 'spy_glass/registry'

opts = {
  path: '/seattle-commercial-electrical-permits',
  cache: SpyGlass::Cache::Memory.new(expires_in: 1200),
  source: 'https://data.seattle.gov/resource/raim-ay5x?'+Rack::Utils.build_query({
    '$limit' => 100,
    '$order' => 'application_date DESC',
    '$where' => <<-WHERE.oneline
      status = 'Application Accepted' AND
      category = 'COMMERCIAL' AND
      applicant_name IS NOT NULL AND
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      application_date IS NOT NULL AND
      address IS NOT NULL AND
      permit_type IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE.oneline
      #{SpyGlass::Salutations.next} #{item['applicant_name'].titleize} has applied for a commercial electrical permit at #{item['address'].titleize}.
      Find out more at #{item['permit_and_complaint_status_url']['url']}
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
