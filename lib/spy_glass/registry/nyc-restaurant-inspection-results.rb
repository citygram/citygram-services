require 'spy_glass/registry'
require 'open-uri'

time_zone = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]

opts = {
	path: '/nyc-restaurant-inspection-results',
	cache: SpyGlass::Cache::Memory.new(expires_in: 300),
	source: 'http://data.cityofnewyork.us/resource/xx67-kt59.json?'+Rack::Utils.build_query({
		'$limit' => 1000,
    '$order' => 'inspection_date DESC',
    '$where' => <<-WHERE.oneline
      inspection_date >= '#{7.days.ago.iso8601}' AND
      street IS NOT NULL AND
      camis IS NOT NULL
    WHERE
		})
}

geocode_cache = ActiveSupport::Cache::MemoryStore.new

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|

  features = collection.map do |item|
    time = Time.iso8601(item['inspection_date']).in_time_zone(time_zone)
    boro = item['boro']

    geoclient_request = 'https://api.cityofnewyork.us/geoclient/v1/address.json?'+Rack::Utils.build_query({
      'houseNumber' => item['building'],
      'street' => item['street'],
      'borough' => item['boro'],
      'app_id' => ENV['GEOCLIENT_APP_ID'],
      'app_key' => ENV['GEOCLIENT_APP_KEY']
      })

    if geocode_cache.read(item['camis']) == nil
      response = JSON.parse(open(geoclient_request).read)
      latitude = response["address"]["latitude"]
      longitude = response["address"]["longitude"]
      geocode_cache.write(item['camis'], [latitude, longitude])
    end

    coords = geocode_cache.read(item['camis'])

    title = 
    case item['action']
    when "No violations were recorded at the time of this inspection."
      if item["grade"]
        "#{Time.iso8601(item['inspection_date']).strftime("%m/%d/%y")} - A restaurant inspection occurred at #{item['dba'].titleize}. Inspection type was #{item['inspection_type']}.  #{item['action']}.Restaurant received the following grade: #{item['grade']}."
      else
        "#{Time.iso8601(item['inspection_date']).strftime("%m/%d/%y")} - A restaurant inspection occurred at #{item['dba'].titleize}. Inspection type was #{item['inspection_type']}. #{item['action']}"
      end
    when "Violations were cited in the following area(s)."
      if item["grade"]
        "#{Time.iso8601(item['inspection_date']).strftime("%m/%d/%y")} - A restaurant inspection occurred at #{item['dba'].titleize}. Inspection type was #{item['inspection_type']}.  The following violation was cited: #{item['violation_description']}  Restaurant received the following grade: #{item['grade']}."
      else
        "#{Time.iso8601(item['inspection_date']).strftime("%m/%d/%y")} - A restaurant inspection occurred at #{item['dba'].titleize}. Inspection type was #{item['inspection_type']}. The following violation was cited: #{item['violation_description']}"
      end
    else
      "#{Time.iso8601(item['inspection_date']).strftime("%m/%d/%y")} - A restaurant inspection occurred at #{item['dba'].titleize}."
    end
    {
      'id' => item['camis'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          coords[0],
          coords[1]
        ]
      },
      'properties' => item.merge('title' => title)
    } 
  end
  {'type' => 'FeatureCollection', 'features' => features}
end