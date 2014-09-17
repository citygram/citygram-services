require 'spy_glass/registry'

opts = {
  path: '/lexington-building-permits',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://104.131.23.252/api/action/datastore_search_sql?'+Rack::Utils.build_query({
    'sql' => <<-WHERE.oneline
      SELECT * from "building-permits"
      WHERE "Date" > (now() - '7 day'::interval)
      AND lat IS NOT NULL
      AND lng IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  features = collection['result']['records'].map do |item|
    title = <<-TITLE.oneline
     A building permit was issued to '#{item['OwnerName']}' of type #{item['PermitType']} at #{item['Address']}."
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
