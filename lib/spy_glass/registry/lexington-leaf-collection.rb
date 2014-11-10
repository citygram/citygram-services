require 'spy_glass/registry'

opts = {
  path: '/lexington-leaf-collection',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://services1.arcgis.com/Mg7DLdfYcSWIaDnu/ArcGIS/rest/services/Leaf_Collection/FeatureServer/1/query?where=++objectid%3Dobjectid&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Meter&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=4326&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&resultOffset=0&resultRecordCount=&returnZ=false&returnM=false&f=pjson&token='
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |esri_formatted|
  features = esri_formatted['features'].map do |feature|
    attributes = feature['attributes']
    title = "Hello! Leaf collection status in your area is currently '#{attributes['Status']}'."
    title += " Collection dates are scheduled for #{attributes['Dates']}." if attributes['Dates']
    title += " Find out more at http://www.lexingtonky.gov/index.aspx?page=573"
    {
      'type' => 'Feature',
      'id' => "#{attributes['OBJECTID']}_#{attributes['Status']}",
      'properties' => {
        'title' => title,
      },
      'geometry' => {
        'type' => 'Polygon',
        'coordinates' => feature['geometry']['rings']
      }
    }
  end

  { 'type' => 'FeatureCollection', 'features' => features }
end
