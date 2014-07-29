require 'spy_glass/registry'

opts = {
  path: '/seattle-code-violation-cases',
  cache: SpyGlass::Cache::Memory.new(expires_in: 1200),
  source: 'http://data.seattle.gov/resource/dk8m-pdjf?'+Rack::Utils.build_query({
    '$limit' => 250,
    '$order' => 'date_case_created DESC',
    '$where' => <<-WHERE.oneline
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      date_case_created IS NOT NULL AND
      address IS NOT NULL AND
      case_group IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE.oneline
      There's been a #{item['case_group'].downcase} code violation near you at #{item['address']}.
      Its status is "#{item['status'].downcase}", and you can find out more at #{item['permit_and_complaint_status_url']['url']}.
    TITLE

    {
      'id' => item['case_number'],
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
