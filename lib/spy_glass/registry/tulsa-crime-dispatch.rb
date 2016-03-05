require 'spy_glass/registry'

opts = {
  path: '/tulsa-crime-dispatch',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://tulsacrimestream.com/api/alerts'
}


time_zone = ActiveSupport::TimeZone['Central Time (US & Canada)']

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  features = collection.map do |item|
  
    #time = Time.iso8601(DateTime.parse(item['updated_at'])).in_time_zone(time_zone).strftime("%m/%d %I:%M %p")
time = DateTime.parse(item['updated_at']).in_time_zone(time_zone).strftime("%m/%d at %I:%M %p")
    title = <<-TITLE.oneline
      #{item['description']} in your area near #{item['address']} 
      on #{time}.
      See all police reports near you https://www.citygram.org/tulsa
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




