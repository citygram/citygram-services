require 'spy_glass/registry'

opts = {
  path: '/clt-historic-district-reviews',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://maps.ci.charlotte.nc.us/arcgis/rest/services/PLN/CharlotteHistoricDistrictCases/FeatureServer/0/query?where=1%3D1&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=4326&gdbVersion=&returnDistinctValues=false&returnIdsOnly=false&returnCountOnly=false&orderByFields=AppDate+desc&groupByFieldsForStatistics=&outStatistics=&returnZ=false&returnM=false&f=pjson'
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |esri_formatted|
  features = esri_formatted['features'].map do |feature|
    attributes = feature['attributes']
    unique_id = attributes['OBJECTID']
    next if feature['geometry'].nil?
    coordinates = feature['geometry']['rings']
    project_description = attributes['ProjDesc'].strip
    project_address = attributes['ProjAddr']
    unique_title = 'New Request for ' +
      project_description + ' at ' +
      project_address + '. For more, call (704) 336-2205 or visit http://j.mp/clt-chd-reviews'

    {
      'type' => 'Feature',
      'id' => unique_id,
      'properties' => attributes.merge(
        'title' => unique_title,
        'url' => 'http://charmeck.org/city/charlotte/planning/HistoricDistricts/Pages/ByDistrict.aspx'
      ),
      'geometry' => { 'type' => 'Polygon', 'coordinates' => coordinates }
    }
  end

  { 'type' => 'FeatureCollection', 'features' => features.reject{ |f| f.nil? } }
end
