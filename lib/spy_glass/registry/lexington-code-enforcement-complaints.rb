require 'spy_glass/registry'

opts = {
  path: '/lexington-code-enforcement-complaints',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://104.131.23.252/api/action/datastore_search_sql?'+Rack::Utils.build_query({
    'sql' => <<-WHERE.oneline
      SELECT * from "complaints-4"
      WHERE "StatusDate" > (now() - '7 day'::interval)
      AND lat IS NOT NULL
      AND lng IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  features = collection['result']['records'].map do |item|
    title = <<-TITLE.oneline
      The code enforcement case number #{item['CaseNo']} was updated to '#{item['Status']}' for #{item['Address']}"
    TITLE
    {
      'id' => "#{item['CaseNo']}_#{item['Status']}",
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
