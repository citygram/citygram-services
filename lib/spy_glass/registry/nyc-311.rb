require 'spy_glass/registry'


query = {
  '$limit' => 1000,
  '$order' => 'created_date DESC',
  '$where' => <<-WHERE.oneline
    created_date >= '#{7.days.ago.iso8601}' AND
    longitude IS NOT NULL AND
    latitude IS NOT NULL AND
    unique_key IS NOT NULL
  WHERE
}

opts = {
  path: '/nyc-311',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.cityofnewyork.us/resource/erm2-nwe9.json?'+ Rack::Utils.build_query(query)
}

time_zone = ActiveSupport::TimeZone['Eastern Time (US & Canada)']
SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    time = Time.iso8601(item['created_date']).in_time_zone(time_zone).strftime("%m/%d  %I:%M %p")
    city = item['city'].capitalize

    title =
      case item['address_type']
      when 'ADDRESS'
        "#{time} - A new 311 case has been opened at #{item['incident_address'].titleize} in #{city}."
      when 'INTERSECTION'
        "#{time} - A new 311 case has been opened at the intersection of #{intersection_street_1 = item['intersection_street_1'].titleize} and #{intersection_street_2 = item['intersection_street_2'].titleize} in #{city}."
      when 'BLOCKFACE'
        "#{time} - A new 311 case has been opened on #{street}, between #{cross_street_2 = item['cross_street_2'].titleize} and #{cross_street_1 = item['cross_street_1'].titleize} in #{city}."
      else
        "#{time} - A new 311 case has been opened on #{item['street_name'].titleize} in #{city}."
      end
    title << " The complaint type is #{item['complaint_type'].downcase} - #{item['descriptor']} and the assigned agency is #{item['agency']}."

    {
      'id' => item['unique_key'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['longitude'].to_f,
          item['latitude'].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {
    'type' => 'FeatureCollection',
    'features' => features
  }
end
