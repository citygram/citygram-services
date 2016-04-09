require 'spy_glass/registry'

# http://maps.ci.charlotte.nc.us/arcgis/rest/services/PLN/PendingRezonings/FeatureServer/0/query

opts = {
  path: '/clt-pending-rezoning',
  cache: SpyGlass::Cache::Memory.new(expires_in: 2400),
  source: 'http://clt.charlotte.opendata.arcgis.com/datasets/e42bb7be0b654aeea83547df4a7dcf22_0.geojson'
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |body|
  features = body["features"].map do |record|
    attrs = record["properties"]
    next if attrs["Type"].nil?
    oid = attrs["Petition"]
    petition = attrs["Petition"]
    petitioner = attrs["Petitioner"]
    from_zone = attrs["ExistZone"]
    to_zone = attrs["ReqZone"]
    r_type = attrs["Type"].downcase if attrs["Type"]
    title = <<-TITLE.oneline.gsub(/\.\.\.\./, '...')
      #{SpyGlass::Salutations.next} #{petitioner} filed a #{r_type} rezoning request from #{from_zone} to #{to_zone}.
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
