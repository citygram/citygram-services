require 'spy_glass/registry'
require 'digest/md5'

helper = Object.new
def helper.collection_season
  2016
end

def helper.begin_date_correction(new_date)
  "There was an error in the leaf map that impacts your address. Leaf vacuuming for your area will begin on #{new_date}. Please prepare your leaves before your window opens to ensure collection. You can also use the gray yard cart and paper yard waste bags to dispose of leaves each week on your regular collection day. We apologize for the mistake and any inconvenience it caused."
end

def helper.in_progress_correction(old_date, new_date)
  "There was an error in the leaf map that impacts your address. Leaf vacuuming for your area began on #{new_date}, not #{old_date}. We are in the process of vacuuming your area, and will be to your house soon if we have not serviced your address already. We apologize for the mistake, and any inconvenience it caused."
end

def helper.manual_message(zone, zone_id, status)
  return {} unless collection_season == 2016

  message = if zone == 'C-1' && status == 'In Progress'
    in_progress_correction('11/14', '11/22')
  elsif zone == 'C-3' && status == 'In Progress'
    in_progress_correction('11/14', '11/18')
  elsif zone == 'C-4' && status == 'Next'
    begin_date_correction('11/28')
  elsif zone == 'C-7' && status == 'Pending'
    begin_date_correction('12/5')
  end

  if (message)
    # hash ensures any change in a message triggers new event in citygram
    message_hash = Digest::MD5.hexdigest(message)
    { message_id: "#{collection_season}_#{zone_id}_#{status}_#{message_hash}", message: message }
  else
    {}
  end
end

def helper.automated_message(zone_id, status, dates)
  link = 'lexingtonky.gov/leaves'
  remember = 'Remember: only residential properties receiving city waste collection services are eligible for this service.'
  prep = 'Remember to prepare your leaves the Sunday before your collection window begins. Pile them in your yard on the edge of the curb, never in the street.'
  more = "Find out more at #{link}"

  message = case status
    when 'In Progress'
      nil
    when 'Next'
      "Hello! Leaf vacuuming is coming soon to your area. It's currently scheduled: #{dates}. We'll let you know if these dates change. #{prep} #{more}"
    when 'Pending'
      "Hello! Leaf vacuuming in your area is currently scheduled: #{dates}. We'll let you know if these dates change. #{prep} If you've moved since last fall, please respond REMOVE and re-enroll in the text notification program for your new address by visiting #{link}"
    when 'Completed'
      "Hello! Leaf collection in your area is complete. For more information please visit #{link}"
  end

  # include collection_season in id. Otherwise if zone ends last year with a status
  # then begins this year with same status, they don't get a message
  { message_id: "#{collection_season}_#{zone_id}_#{status}", message: message }
end

def helper.message(zone, zone_id, status, dates)
  manual = manual_message(zone, zone_id, status)

  manual[:message] ? manual : automated_message(zone_id, status, dates)
end

opts = {
  path: '/lexington-leaf-collection',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://maps.lexingtonky.gov/lfucggis/rest/services/leafcollection/MapServer/1/query?where=1%3D1&text=&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&relationParam=&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=4326&returnIdsOnly=false&returnCountOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&returnZ=true&returnM=true&gdbVersion=&returnDistinctValues=false&f=pjson'
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |esri_formatted|
  features = esri_formatted['features'].map do |feature|
    zone_id = feature['attributes']['GIS_master.DBO.LeafCollection.OBJECTID']
    status = feature['attributes']['GIS_master.DBO.LeafZoneSchedule.Status']
    dates = feature['attributes']['GIS_master.DBO.LeafZoneSchedule.Dates']
    zone = feature['attributes']['GIS_master.DBO.LeafZoneSchedule.Zone']
    message_object = helper.message(zone, zone_id, status, dates)
    message = message_object[:message]

    if message.nil?
      nil
    else
      {
        'type' => 'Feature',
        'id' => "#{message_object[:message_id]}",
        'properties' => {
          'title' => message,
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
