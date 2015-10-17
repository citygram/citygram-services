require 'spy_glass/registry'

# http://maps.ci.charlotte.nc.us/arcgis/rest/services/PLN/PendingRezonings/FeatureServer/0/query

opts = {
  path: '/clt-pending-rezoning',
  cache: SpyGlass::Cache::Memory.new(expires_in: 2400),
  source: 'http://clt.charlotte.opendata.arcgis.com/datasets/28dd5cc6e9254140bfd603f44dd3f4a5_0.geojson?orderByFields=Received+DESC'
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |body|
  features = body["features"].map do |record|
    attrs = record["properties"]
    oid = attrs["OBJECTID"]
    petition = attrs["Petition"]
    petitioner = attrs["Petitioner"]
    from_zone = attrs["ExistZone"]
    to_zone = attrs["ReqZone"]
    r_type = attrs["Type"].downcase
    title = <<-TITLE.oneline.gsub(/\.\.\.\./, '...')
      #{SpyGlass::Salutations.next} #{petitioner} filed a #{r_type} rezoning request from #{from_zone} to #{to_zone}.
      Learn more: #{attrs['Hyperlink']}
    TITLE

    {
      'id' => record['properties']["OBJECTID"],
      'type' => 'Feature',
      'properties' => record.merge('title' => title)
    }
  end

  { 'type' => 'FeatureCollection', 'features' => features }
end
