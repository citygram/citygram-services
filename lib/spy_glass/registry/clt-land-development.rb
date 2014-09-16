require 'spy_glass/registry'

sql = <<-SQL.gsub(/(\s{2,}|\n)/, " ").strip
SELECT "9f57ae4b-fc62-4ae3-895d-aece0e759b5c".*
FROM "9f57ae4b-fc62-4ae3-895d-aece0e759b5c"
WHERE "9f57ae4b-fc62-4ae3-895d-aece0e759b5c"."X_COORD" IS NOT NULL
AND "9f57ae4b-fc62-4ae3-895d-aece0e759b5c"."X_COORD" != '0'
AND "9f57ae4b-fc62-4ae3-895d-aece0e759b5c"."Y_COORD" IS NOT NULL
AND "9f57ae4b-fc62-4ae3-895d-aece0e759b5c"."Y_COORD" != '0'
AND "9f57ae4b-fc62-4ae3-895d-aece0e759b5c"."PROJECTDESCRIPTION" IS NOT NULL
AND "9f57ae4b-fc62-4ae3-895d-aece0e759b5c"."OWNERNAME" IS NOT NULL
ORDER BY "9f57ae4b-fc62-4ae3-895d-aece0e759b5c"."RECORDOPENDATE" DESC
LIMIT 100
SQL

opts = {
  path: '/clt-land-development',
  cache: SpyGlass::Cache::Memory.new(expires_in: 2400),
  source: 'http://www.civicdata.com/api/action/datastore_search_sql?'+Rack::Utils.build_query(sql: sql)
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |body|
  features = body['result']['records'].map do |record|
    lat, lng = SpyGlass::Utils.point_srid_transform(record['X_COORD'], record['Y_COORD'], 3359, 4326)

    {
      'id' => record['PROJECTNUMBER'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [lat,lng]
      },
      'properties' => record.merge(
        'title' => record['PROJECTDESCRIPTION'],
        'url' => record['URL']
      )
    }
  end

  { 'type' => 'FeatureCollection', 'features' => features }
end
