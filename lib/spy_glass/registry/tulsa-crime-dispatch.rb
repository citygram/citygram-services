require 'spy_glass/registry'

opts = {
  path: '/tulsa-crime-dispatch',
  cache: SpyGlass::Cache::Memory.new(expires_in: 2400),
  source: 'https://www.tulsacrimestreams.com/api/crimes'
}


SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  features = collection['Incidents']['Incident'].map do |item|
    title = <<-TITLE.oneline
      The Tulsa Police Department responded to 
      a #{item['description']} was
      reported at #{item['address']} 
      This issue is considered #{item['class']}
      on #{item['updated_at']}.
      See all the dispatches near you at https://www.citygram.org/tulsa
    TITLE
    {
      'id' => "#{item['id']}",
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          item['lng'].to_f,
          item['lat'].to_f          
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end
  
  {'type' => 'FeatureCollection', 'features' => features}
end




