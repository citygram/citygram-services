require 'spy_glass/registry'

opts = {
  path: '/lexington-foreclosure-sales',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://www.civicdata.com/api/action/datastore_search_sql?'+Rack::Utils.build_query({
    'sql' => <<-WHERE.oneline
      SELECT * from "197e1770-3877-4668-8858-1bb1c54754e9"
      WHERE "SALEDT" > (now() - '30 day'::interval)
      AND lat IS NOT NULL
      AND lng IS NOT NULL
      LIMIT 1000
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  features = collection['result']['records'].map do |item|
    date = DateTime.parse(item['SALEDT'])
    title = <<-TITLE.oneline
      A foreclosed property at #{ActiveSupport::Inflector.titleize(item['ADDRESS'])}
      sold for #{Money.us_dollar(item['PRICE'].to_i * 100).format(no_cents: true)}
      on #{date.strftime('%B')} #{ActiveSupport::Inflector.ordinalize(date.day)}
    TITLE
    {
      'id' => "#{item['SALEKEY']}",
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
