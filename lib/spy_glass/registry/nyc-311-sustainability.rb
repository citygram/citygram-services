require 'spy_glass/registry'

query = {
  '$limit' => 1000,
  '$order' => 'created_date DESC',
  '$where' => <<-WHERE.oneline
    created_date >= '#{SpyGlass::Utils.last_week_floating_timestamp}' AND
    longitude IS NOT NULL AND
    latitude IS NOT NULL AND
    
    (
    (descriptor LIKE '%Air: Open Fire Commercial (AC2)%') OR
    (descriptor LIKE '%Air: Smoke Chimney or vent (AS1)%') OR
    (descriptor LIKE '%Air: Smoke Other (Use Comments) (AA5)%') OR
    (descriptor LIKE '%Air: Open Fire Construction/Demolition (AC4)%') OR
    (descriptor LIKE '%Air: Open Fire Residential (AC1)%') OR
    (descriptor LIKE '%Air: Smoke Residential (AA1)%') OR
    (descriptor LIKE '%Air: Smoke Vehicular (AA4)%') OR
    (descriptor LIKE '%Air: Odor/Fumes Vehicle Idling (AD3)%') OR
    (descriptor LIKE '%Air: Smoke Commercial (AA2)%') OR
    (descriptor LIKE '%Air: Other Air Problem (Use Comments) (AZZ)%') OR
    (descriptor LIKE '%Recycling Issue%') OR
    (descriptor LIKE '%Recycling%') OR
    (descriptor LIKE '%Recycling Issue%') OR
    (descriptor LIKE '%1RG Missed Recycling Paper%') OR
    (descriptor LIKE '%2R Bulk-Missed Recy Collection%') OR
    (descriptor LIKE '%1RO Missed Recycling Organics%') OR
    (descriptor LIKE '%1RB Missed Recycling - M/G/Pl%') OR
    (descriptor LIKE '%1R Missed Recycling-All Materials%') OR
    (descriptor LIKE '%6R Overflowing Recycling Baskets%') OR
    (descriptor LIKE '%Illegal Use Of A Hydrant (CIN)%') OR
    (descriptor LIKE '%Wasting Faucets,Sinks,Flushometer,Urinal,Etc. - Private Residence (CWR)%') OR
    (descriptor LIKE '%Swimming Pool, Illegal Filling - Private Residence (CER)%') OR
    (descriptor LIKE '%Wasting Faucets,Sinks,Flushometer,Urinal,Etc. - Other (CWO)%') OR
    (descriptor LIKE '%Illegal Use Of Hose - Private Residence (CCR)%') OR
    (descriptor LIKE '%Illegal Use Of Hose - Other (CCO)%') OR
    (descriptor LIKE '%Other Water Waste Problem, (Use Comments) (CZZ)%')
    ) AND

    unique_key IS NOT NULL
  WHERE
}

opts = {
  path: '/nyc-311-sustainability',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://data.cityofnewyork.us/resource/fhrw-4uyv.json?'+ Rack::Utils.build_query(query)
}

time_zone = ActiveSupport::TimeZone['Eastern Time (US & Canada)']
SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    time = Time.iso8601(item['created_date']).in_time_zone(time_zone).strftime("%m/%d  %I:%M %p")

    title =
      case item['address_type']
      when 'ADDRESS'
        "#{time} | #{item['descriptor']} at #{item['incident_address'].titleize}."
      when 'INTERSECTION'
        "#{time} | #{item['descriptor']} at #{item['intersection_street_1'].titleize} and #{item['intersection_street_2'].titleize}."
      when 'BLOCKFACE'
        "#{time} | #{item['descriptor']} on #{item['street_name'].titleize}, between #{item['cross_street_2'].titleize} and #{item['cross_street_1'].titleize}."
      else
        "#{time} | #{item['descriptor']} on #{item['street_name']}."
      end
    title << " #{item['agency']}, #{item['complaint_type']}."

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
