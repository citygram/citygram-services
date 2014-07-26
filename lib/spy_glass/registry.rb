require 'dedent'
require 'rack/utils'
require 'spy_glass/clients'

opts = {
  path: '/seattle-pd-911-incidents',
  cache: SpyGlass::Caches::Memory.new,
  source: 'http://data.seattle.gov/resource/3k2p-39jp?'+Rack::Utils.build_query({
    '$limit' => 100,
    '$order' => 'event_clearance_date DESC',
    '$where' => <<-WHERE.oneline
      longitude IS NOT NULL AND
      latitude IS NOT NULL AND
      event_clearance_date IS NOT NULL AND
      event_clearance_description IS NOT NULL AND
      hundred_block_location IS NOT NULL
    WHERE
  })
}

SpyGlass::Registry << SpyGlass::Clients::Socrata.new(opts) do |collection|
  features = collection.map do |item|
    title = <<-TITLE.dedent
      A 911 incident has occurred near you at #{item['hundred_block_location']}. It was described as "#{item['event_clearance_description'].downcase}" and has been cleared.
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
