require 'spy_glass/registry'

opts = {
  path: '/lexington-leaf-collection',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://services1.arcgis.com/Mg7DLdfYcSWIaDnu/ArcGIS/rest/services/Leaf_Collection/FeatureServer/1/query?where=++objectid%3Dobjectid&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Meter&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=4326&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&resultOffset=0&resultRecordCount=&returnZ=false&returnM=false&f=pjson&token='
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  esri_formatted = JSON.parse(collection)

  features = esri_formatted['features'].map do |item|
    title = "Hello! Leaf collection status in your area is now '#{attributes['Status']}'."
    title += " Collection dates are #{attributes['Dates']}" if attributes['Dates']
    {
      'type' => 'Feature',
      'id' => attributes['OBJECTID'],
      'properties' => {
        'title' => item.merge('title' => title)
      },
      'geometry' => {
        'type' => 'Polygon',
        'coordinates' => feature['geometry']['rings']
      }
    }
  end    

  { 'type' => 'FeatureCollection', 'features' => features }
end
