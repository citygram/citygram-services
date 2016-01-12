require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]

opts = {
  path: '/miami-building-permits',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://opendata.miamidade.gov/resource/kw55-e2dj.json?'+Rack::Utils.build_query({
    '$limit' => 1000,
    '$order' => 'ticket_created_date_time DESC',
    '$where' => <<-WHERE.oneline
      ticket_created_date_time >= '#{7.days.ago.iso8601}' AND
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      street_address IS NOT NULL AND
      issue_type IS NOT NULL AND
      ticket_id IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    time = Time.iso8601(item['ticket_created_date_time']).in_time_zone(time_zone)

    city = item['city']
    title =
      "#{Time.iso8601(item['ticket_created_date_time']).strftime("%m/%d  %I:%M %p")} - A new building permit has been issued at #{item['street_address']} to #{item['owner_name']}."

    # title << " The complaint type is #{item['issue_type']} and the assigned agency is #{item['case_owner'].gsub('_', ' ')}."
    location_regex = /\((-?[\d.]+)°,\s(-?[\d.]+)°\)/ 
    location_match = location_regex.match item['location']
    

    {
      'id' => item['ticket_id'],
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          location_match[1].to_f,
          location_match[2].to_f
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end

