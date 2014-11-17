require 'spy_glass/registry'

opts = {
  path: '/lexington-building-permits',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://www.civicdata.com/api/action/datastore_search_sql?'+Rack::Utils.build_query({
    'sql' => <<-WHERE.oneline
      SELECT * from "2691aff1-e555-48d3-9188-aebf1fa8323e"
      WHERE "Date" > (now() - '7 day'::interval)
      AND lat IS NOT NULL
      AND lng IS NOT NULL
      LIMIT 1000
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  features = collection['result']['records'].map do |item|
    title = <<-TITLE.oneline
     A building permit application has been submitted near you at #{item['Address'].titlecase}. The permit is for #{item['PermitType'].titlecase} and its ID is #{item['ID']}.
    TITLE
    {
      'id' => item['ID'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['lat'].to_f,
          item['lng'].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
