require 'spy_glass/registry'

resource_id = 'e53f0901-62fb-443d-a22c-9a5afc851aef'

sql = <<-SQL.gsub(/(\s{2,}|\n)/, " ").strip
SELECT "#{resource_id}".*
FROM "#{resource_id}"
WHERE "#{resource_id}"."X_COORD" IS NOT NULL
AND "#{resource_id}"."X_COORD" NOT IN ('0', '')
AND "#{resource_id}"."Y_COORD" IS NOT NULL
AND "#{resource_id}"."Y_COORD" NOT IN ('0', '')
AND "#{resource_id}"."ProjectDescription" IS NOT NULL
AND "#{resource_id}"."URL" IS NOT NULL
ORDER BY "#{resource_id}"."RecordOpenDate" DESC
LIMIT 100
SQL

opts = {
  path: '/clt-land-development',
  cache: SpyGlass::Cache::Memory.new(expires_in: 2400),
  source: 'http://www.civicdata.com/api/action/datastore_search_sql?'+Rack::Utils.build_query(sql: sql)
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |body|
  features = body['result']['records'].map do |record|
    # require 'debugger';debugger
    address = record['Address'].gsub(/,\ CHARLOTTE,\ NC\ \d*/, '').titlecase
    description = SpyGlass::Utils.truncate(record['ProjectDescription'], length: 80)

    title = <<-TITLE.oneline.gsub(/\.\.\.\./, '...')
      #{SpyGlass::Salutations.next} A Land Development plan for #{address} has been submitted.
      The description is: #{description}.
      Learn more: #{record['URL']}
    TITLE

    coordinates = SpyGlass::Utils.point_srid_transform(record['X_COORD'], record['Y_COORD'], 3359, 4326)

    {
      'id' => record['_id'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => coordinates
      },
      'properties' => record.merge('title' => title)
    }
  end

  { 'type' => 'FeatureCollection', 'features' => features }
end
