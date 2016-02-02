# coding: utf-8
require 'spy_glass/registry'
require 'pp'

time_zone = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]

source_base = 'https://opendata.miamidade.gov/resource/vvjq-pfmc.json'
options = {
  '$limit' => 1000,
  '$order' => 'permit_issued_date DESC',
  '$where' => <<-WHERE.oneline
    permit_issued_date IS NOT NULL AND
    permit_issued_date >= '#{7.days.ago.iso8601}' AND
    location IS NOT NULL
  WHERE
}

source_url = source_base + '?' + Rack::Utils.build_query(options)

opts = {
  path: '/miami-building-permits',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: source_url
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|

    time = Time.iso8601(item[0]['ticket_created_date_time']).in_time_zone(time_zone)
pp item

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
