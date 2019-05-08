require 'spy_glass/registry'


opts = {
  path: '/clt-pending-rezoning',
  cache: SpyGlass::Cache::Memory.new(expires_in: 2400),
  source: 'https://opendata.arcgis.com/datasets/0582732131884194ab102111813542c3_50.geojson'
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |body|
  features = body["features"].map do |record|
    attrs = record["properties"]
    puts attrs.inspect
    next if attrs["Type"].nil?
    next if attrs["Status"] != "Pending" # only pending rezonings are relevant
    oid = attrs["Petition"]
    petition = attrs["Petition"]
    petitioner = attrs["Petitioner"]
    from_zone = attrs["ExistZone"]
    to_zone = attrs["ReqZone"]
    r_type = attrs["Type"].downcase if attrs["Type"]
    title = <<-TITLE.oneline.gsub(/\.\.\.\./, '...')
      #{petitioner} filed a #{r_type} rezoning request from #{from_zone} to #{to_zone}.
      Learn more: #{attrs['Hyperlink']}
    TITLE

    {
      'id' => record['properties']["OBJECTID"],
      'type' => 'Feature',
      'properties' => attrs.merge('title' => title),
      'geometry' => record["geometry"]
    }
  end

  { 'type' => 'FeatureCollection', 'features' => features.reject{ |f| f.nil? } }
end
