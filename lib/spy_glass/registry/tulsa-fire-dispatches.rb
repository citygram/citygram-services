require 'spy_glass/registry'

opts = {
  path: '/tulsa-fire-dispatch',
  cache: SpyGlass::Cache::Memory.new(expires_in: 2400),
  source: 'https://www.cityoftulsa.org/apps/opendata/tfd_dispatch.jsn'
}


SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  features = collection['Incidents']['Incident'].map do |item|
    title = <<-TITLE.oneline
      The Tulsa Fire Department responded to 
      a #{item['Problem']} 
      reported at #{item['Address']} 
      on #{item['ResponseDate']}.
      See all the dispatches near you at https://www.citygram.org/tulsa
    TITLE
    {
      'id' => "#{item['IncidentNumber']}",
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['Longitude'].to_f,
          item['Latitude'].to_f          
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end
  
  {'type' => 'FeatureCollection', 'features' => features}
end




