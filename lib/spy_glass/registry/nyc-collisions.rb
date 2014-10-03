require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]

opts = {
  path: '/nyc-collisions',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://data.cityofnewyork.us/resource/h9gi-nx95.json?'+Rack::Utils.build_query({
    '$limit' => 1000,
    '$order' => 'date DESC',
    '$where' => <<-WHERE.oneline
      date >= '#{7.days.ago.iso8601}' AND
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      unique_key IS NOT NULL 
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|

    puts item

    title = 
      "#{Time.iso8601(item['date']).strftime("%m/%d")} #{item['time']} - A vehicle collision occurred" 

    if item['on_street_name'] && item['off_street_name']
      title << " at #{item['on_street_name'].titleize} and #{item['off_street_name'].titleize}. "
    elsif item['on_street_name'] && !item['off_street_name']
      title << " at #{item['on_street_name'].titleize}. "
    else 
      title << " nearby. "
    end

    if item['contributing_factor_vehicle_1'] && !item['contributing_factor_vehicle_2']
      title << "The contributing factor was #{item['contributing_factor_vehicle_1']}. "
    elsif item['contributing_factor_vehicle_1'] && item['contributing_factor_vehicle_2']
      title << "The contributing factors were #{item['contributing_factor_vehicle_1']} and #{item['contributing_factor_vehicle_2']}. "
    end

    if item['number_of_persons_injured'].to_i > 0
      title << "Persons injured: #{item['number_of_persons_injured']}. "
    end

    if item['number_of_persons_killed'].to_i > 0
      title << "Persons killed: #{item['number_of_persons_killed']}. "
    end


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

  {'type' => 'FeatureCollection', 'features' => features}
end

