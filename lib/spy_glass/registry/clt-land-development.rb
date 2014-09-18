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

helper = Object.new.extend(ActionView::Helpers::TextHelper)

opts = {
  path: '/clt-land-development',
  cache: SpyGlass::Cache::Memory.new(expires_in: 2400),
  source: 'http://www.civicdata.com/api/action/datastore_search_sql?'+Rack::Utils.build_query(sql: sql)
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |body|
  features = body['result']['records'].map do |record|
    address = record['ADDRESS'].gsub(/,\ CHARLOTTE,\ NC\ \d*/, '').titlecase
    description = helper.truncate(record['PROJECTDESCRIPTION'], length: 80)

    # fix busted urls
    url = record['URL'].gsub('%63', '?')

    title = <<-TITLE.oneline
      #{SpyGlass::Salutations.next} A Land Development plan for #{address} has been submitted.
      The description is: #{description}.
      Learn more: #{url}
    TITLE

    lon, lat = SpyGlass::Utils.point_srid_transform(record['X_COORD'], record['Y_COORD'], 3359, 4326)

    {
      'id' => record['PROJECTNUMBER'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [lon,lat]
      },
      'properties' => record.merge('title' => title)
    }
  end

  { 'type' => 'FeatureCollection', 'features' => features }
end
