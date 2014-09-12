require 'spy_glass/registry'

opts = {
  path: '/lexington-code-enforcement-complaints',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://104.131.23.252/api/action/datastore_search_sql?'+Rack::Utils.build_query({
    'resource_id' => 'complaints-2',
    'sql' => <<-WHERE.oneline
      SELECT * from "complaints-2"
      WHERE "StatusDate" > (now() - '7 day'::interval)
      AND lat IS NOT NULL
      AND lng IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  features = collection['result']['records'].map do |item|
    title = <<-TITLE.oneline
      A code complaint has been opened or updated near you at #{item['Address'].titlecase}. Its status is '#{item['Status']}' & its case number is '#{item['CaseNo']}'.
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
