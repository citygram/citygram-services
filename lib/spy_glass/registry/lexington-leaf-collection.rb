require 'spy_glass/registry'

json = JSON.parse(File.read('lib/spy_glass/registry/lexington-leaf-collection-zones.json'))
zones = Hash[json['features'].map { |z| [z['properties']['Subzone'], z['geometry']] }]

helper = Object.new

def helper.title(status, dates)
  link = 'lexingtonky.gov/index.aspx?page=573'
  remember = 'Remember: only residential properties receiving city waste collection services are eligible for this service.'
  more = "Find out more at #{link}"
  case status
    when 'In Progress'
      "Hello! Leaf collection is in progress in your area from #{dates}. #{remember} #{more}"
    when 'Next'
      "Hello! Leaf collection is coming soon to your area. It's currently scheduled for #{dates} but we'll let you know if these dates change. #{remember} #{more}"
    when 'Pending'
      "Hello! Leaf collection in your area is currently scheduled for #{dates} but we'll let you know if these dates change. #{remember} #{more}"
    when 'Completed'
      "Hello! Leaf collection in your area is complete. For more information please visit #{link}"
  end
end

opts = {
  path: '/lexington-leaf-collection',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://gis.lexingtonky.gov/lfucggis/rest/services/leafcollection/MapServer/1/query?where=1%3D1&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=4326&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=true&returnM=true&gdbVersion=&returnDistinctValues=false&f=pjson'
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |esri_formatted|
  features = esri_formatted['features'].map do |feature|
    object_id = feature['attributes']['gis.DL.LeafCollection.OBJECTID']
    status = feature['attributes']['gis.DL.LeafZoneSchedule.Status']
    dates = feature['attributes']['gis.DL.LeafZoneSchedule.Dates'].gsub(' - ', '-')
    zone = feature['attributes']['gis.DL.LeafZoneSchedule.Zone']

    {
      'type' => 'Feature',
      'id' => "#{object_id}_#{status}",
      'properties' => {
        'title' => helper.title(status, dates)
      },
      'geometry' => zones.fetch(zone)
    }
  end

  { 'type' => 'FeatureCollection', 'features' => features }
end
