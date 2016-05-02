# coding: utf-8
require 'spy_glass/registry'

time_zone = ActiveSupport::TimeZone["Eastern Time (US & Canada)"]

source_base = 'https://opendata.miamidade.gov/resource/vvjq-pfmc.json'
options = {
  '$limit' => 1000,
  '$order' => 'permit_issued_date DESC',
  '$where' => <<-WHERE.oneline
    permit_issued_date IS NOT NULL AND
    permit_issued_date >= '#{7.days.ago.strftime("%Y-%m-%dT%H:%M:%S")}' AND
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
    time = Time.iso8601(item['permit_issued_date']).in_time_zone(time_zone)

    city = item['city']
    title =
      "#{Time.iso8601(item['permit_issued_date']).strftime("%m/%d  %I:%M %p")} - A new building permit has been issued at #{item['location_address']} to #{item['owner_name']}."

    # title << " The complaint type is #{item['issue_type']} and the assigned agency is #{item['case_owner'].gsub('_', ' ')}."


    {
      'id' => item['permit_number'],
      'type' => 'Feature',
      'geometry' => item['location'],
      'properties' => item.merge('title' => title)
    }
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
