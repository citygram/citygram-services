require 'spy_glass/registry'

helper = Object.new

def helper.title(status, dates)
  link = 'lexingtonky.gov/leaves'
  remember = 'Remember: only residential properties receiving city waste collection services are eligible for this service.'
  prep = 'Remember to prepare your leaves the Sunday before your collection window begins. Pile them in your yard on the edge of the curb, never in the street.'
  more = "Find out more at #{link}"

  case status
    when 'In Progress'
      nil
    when 'Next'
      "Hello! Leaf vacuuming is coming soon to your area. It's currently scheduled: #{dates}. We'll let you know if these dates change. #{prep} #{more}"
    when 'Pending'
      "Hello! Leaf vacuuming in your area is currently scheduled: #{dates}. We'll let you know if these dates change. #{prep} If you've moved since last fall, please respond REMOVE and re-enroll in the text notification program for your new address by visiting #{link}"
    when 'Completed'
      "Hello! Leaf collection in your area is complete. For more information please visit #{link}"
  end
end

opts = {
  path: '/lexington-leaf-collection',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://maps.lexingtonky.gov/lfucggis/rest/services/leafcollection/MapServer/1/query?where=1%3D1&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=4326&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=true&returnM=true&gdbVersion=&returnDistinctValues=false&f=pjson'
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |esri_formatted|
  features = esri_formatted['features'].map do |feature|
    object_id = feature['attributes']['GIS_master.DBO.LeafCollection.OBJECTID']
    status = feature['attributes']['GIS_master.DBO.LeafZoneSchedule.Status']
    dates = feature['attributes']['GIS_master.DBO.LeafZoneSchedule.Dates']
    title = helper.title(status, dates)

    # necessary if any of the statuses from this year are the same as their last status from prev year
    collection_season = '2016'

    if title.nil?
      nil
    else
      {
        'type' => 'Feature',
        'id' => "#{collection_season}_#{object_id}_#{status}",
        'properties' => {
          'title' => helper.title(status, dates)
        },
        'geometry' => {
          type: 'Polygon',
          coordinates: feature['geometry']['rings']
        }
      }
    end
  end

  { 'type' => 'FeatureCollection', 'features' => features.compact }
end

opts[:path] = '/lexington-leaf-collection-citygram-events-format'

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |esri_formatted|
  features = esri_formatted['features'].map do |feature|
    object_id = feature['attributes']['GIS_master.DBO.LeafCollection.OBJECTID']
    status = feature['attributes']['GIS_master.DBO.LeafZoneSchedule.Status']
    dates = feature['attributes']['GIS_master.DBO.LeafZoneSchedule.Dates']
    # necessary if any of the statuses from this year are the same as their last status from prev year
    collection_season = '2016'
    title =  "Hello! Leaf collection begins soon. For more information please visit https://lexingtonky.gov/leaves"

    {
      'type' => 'Feature',
      'feature_id' => "#{collection_season}_#{object_id}_#{status}",
      'title' => helper.title(status, dates),
      'status' => feature['attributes']['GIS_master.DBO.LeafZoneSchedule.Zone'],
      'properties' => {
        'title' => helper.title(status, dates)
      },
      'geom' => JSON.generate({
        type: 'Polygon',
        coordinates: feature['geometry']['rings']
      })
    }
  end

  features
end
