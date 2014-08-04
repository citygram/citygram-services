require 'spy_glass/registry'

opts = {
  path: '/seattle-pd-911-incidents',
  cache: SpyGlass::Cache::Memory.new,
  source: 'http://data.seattle.gov/resource/3k2p-39jp?'+Rack::Utils.build_query({
    '$limit' => 100,
    '$order' => 'event_clearance_date DESC',
    '$where' => <<-WHERE.oneline
      event_clearance_group != 'TRAFFIC RELATED CALLS' AND
      event_clearance_group != 'FALSE ALARMS' AND
      initial_type_description != 'DISTURBANCE, MISCELLANEOUS/OTHER' AND
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      event_clearance_date IS NOT NULL AND
      event_clearance_description IS NOT NULL AND
      hundred_block_location IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Client::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE.oneline
      A 911 incident has occurred near you at #{item['hundred_block_location']}.
      It was described as "#{item['event_clearance_description'].downcase}" and has been cleared.
    TITLE

    {
      'id' => item['cad_cdw_id'],
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
