require 'spy_glass/registry'


opts = {
  path: '/clt-pending-rezoning',
  cache: SpyGlass::Cache::Memory.new(expires_in: 2400),
  source: 'https://opendata.arcgis.com/datasets/0582732131884194ab102111813542c3_50.geojson'
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |body|
  features = body["features"].map do |record|
    attrs = record["properties"]
    next if attrs["PlanType"].nil?
    next if !["Pending", "In Progress"].include?(attrs["AppStatus"].strip)
    oid = attrs["Petition"]
    petition = attrs["Petition"]
    petitioner = attrs["Developer"]
    from_zone = attrs["ExistZone"]
    to_zone = attrs["Zoning"]
    r_type = attrs["PlanType"]
    addr = attrs["Address"].strip
    rz_petit = attrs["RezonPetit"]
    proj = attrs["ProjName"]
    status = attrs["AppStatus"].strip.downcase
    t = "#{petitioner} has filed a rezoning request to #{to_zone}"
    t << " (#{rz_petit})" if rz_petit.strip.length > 0
    t << " for #{proj}"
    t << " at #{addr}" if addr.strip.length > 0
    t << ". Its status is #{status}"
    t << ". Learn more: #{attrs['Hyperlink']}"
    title = t.oneline.gsub(/\.\.\.\./, '...')
    {
      'id' => record['properties']["OBJECTID"],
      'type' => 'Feature',
      'properties' => attrs.merge('title' => title),
      'geometry' => record["geometry"]
    }
  end

  { 'type' => 'FeatureCollection', 'features' => features.reject{ |f| f.nil? } }
end
