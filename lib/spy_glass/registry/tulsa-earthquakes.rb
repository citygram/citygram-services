require 'spy_glass/registry'

opts = {
  path: '/tulsa-earthquakes',
  cache: SpyGlass::Cache::Memory.new(expires_in: 2400),
  source: 'https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&latitude=36.154135&longitude=-95.992828&maxradiuskm=100'
}


SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  features = collection['features'].map do |item|

   time = Time.at("#{item['properties']['time']}".to_i / 1000).localtime("-06:00").ctime
    title = "There was an earthquake #{item['properties']['place']} of magnitude #{item['properties']['mag']} on " + time + ". See all the earthquakes near you at earthquake.usgs.gov"




    {
      'id' => "#{item['properties']['ids']}",
      'type' => 'Feature',
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          -95.992828,
          36.154135        
        ]
      },
      'properties' => item.merge('title' => title)
    }
  end
  
  {'type' => 'FeatureCollection', 'features' => features}
end




