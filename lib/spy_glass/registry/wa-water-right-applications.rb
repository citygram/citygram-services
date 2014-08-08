require 'spy_glass/registry'

opts = {
  path: '/wa-water-right-applications',
  cache: SpyGlass::Cache::Memory.new(expires_in: 3600),
  source: 'http://data.wa.gov/resource/9ubz-5r4b?'+Rack::Utils.build_query({
    '$limit' => 100,
    '$order' => 'priority_date DESC',
    '$where' => <<-WHERE.oneline
      document_type IS NOT NULL AND
      priority_date IS NOT NULL AND
      person_last_or_organization_name IS NOT NULL AND
      source_name IS NOT NULL AND
      wria_nm IS NOT NULL AND
      longitude1 IS NOT NULL AND
      latitude1 IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = case item['document_type'].downcase
    when 'newapp'
      'A new water right application was '
    when 'change application'
      'An application for change of water right was '
    end

    title += <<-TITLE.oneline
      filed in #{item['county_name'].titleize} County for the
      #{item['wria_nm']} watershed. The person/org listed is "#{item['person_last_or_organization_name']}".
      Find out more: #{item['map_url']['url']}.
    TITLE

    {
      'id' => item['wr_doc_id'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['longitude1'].to_f,
          item['latitude1'].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
