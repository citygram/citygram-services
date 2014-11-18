require 'spy_glass/registry'

opts = {
  path: '/lexington-code-enforcement-complaints',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://www.civicdata.com/api/action/datastore_search_sql?'+Rack::Utils.build_query({
    'sql' => <<-WHERE.oneline
      SELECT * from "ad346da7-ce88-4c77-a0e1-10ff09bb0622"
      WHERE "StatusDate" > (now() - '7 day'::interval)
      AND lat IS NOT NULL
      AND lng IS NOT NULL
      LIMIT 1000
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  features = collection['result']['records'].map do |item|
    link = "lfucg.github.io/cityview/details.html?type=code&ID=#{item['_id']}"
    title = <<-TITLE.oneline
      A code complaint has been opened or updated near you at #{item['Address'].titlecase}.
      Its status is '#{item['Status']}'. Find out more at #{link}
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
