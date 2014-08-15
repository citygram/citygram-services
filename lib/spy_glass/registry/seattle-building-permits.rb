require 'spy_glass/registry'

opts = {
  path: '/seattle-building-permits',
  cache: SpyGlass::Cache::Memory.new(expires_in: 1200),
  source: 'https://data.seattle.gov/resource/mags-97de?'+Rack::Utils.build_query({
    '$limit' => 100,
    '$order' => 'application_date DESC',
    '$where' => <<-WHERE.oneline
      status = 'Application Accepted' AND
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      application_date IS NOT NULL AND
      category IS NOT NULL AND
      address IS NOT NULL AND
      permit_type IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE.oneline
      #{SpyGlass::Salutations.next} A building permit for #{item['category'].downcase} #{item['permit_type'].downcase} has been submitted near you at #{item['address']}.
      The proposed value is #{Money.us_dollar(item['value'].to_i*100).format(no_cents: true)}.
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
