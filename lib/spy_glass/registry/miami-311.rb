require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]

opts = {
  path: '/miami-311',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'https://opendata.miamidade.gov/resource/dj6j-qg5t.json?'+Rack::Utils.build_query({
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
      "#{Time.iso8601(item['ticket_created_date_time']).strftime("%m/%d  %I:%M %p")} - A new 311 case has been opened at #{item['street_address']}."

    title << " The complaint type is #{item['issue_type']} and the assigned agency is #{item['case_owner']}."

    {
      'id' => item['ticket_id'],
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

