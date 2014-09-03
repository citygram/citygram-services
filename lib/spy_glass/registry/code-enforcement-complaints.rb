require 'spy_glass/registry'

opts = {
  path: '/code-enforcement-complaints',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://104.131.23.252/api/action/datastore_search_sql?'+Rack::Utils.build_query({
    'resource_id' => 'complaints-2',
    'sql' => <<-WHERE.oneline
      select * from "complaints-2"
      where "StatusDate" > (now() - '7 day'::interval)
      and lat IS NOT NULL
      and lng IS NOT NULL
    WHERE
  })
}

downcase_words = %w(intersection of and).freeze
downcase_regexp = Regexp.union(downcase_words.map{|w| /#{w}/i })

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection['result']['records'].map do |item|
    title = "Code Enforcement case status updated to '#{item['Status']}'"
    {
      'id' => item['CaseNo'],
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
    # 'foo'
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
