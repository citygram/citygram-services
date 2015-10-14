require 'spy_glass/registry'

opts = {
  path: '/tulsa-street-projects',
  cache: SpyGlass::Cache::Memory.new(expires_in: 2400),
  source: 'https://codefortulsa.opendatasoft.com/api/records/1.0/search?dataset=street-and-bridge-projects'
}


SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  features = collection['records'].map do |item|
    title = <<-TITLE.oneline
      There is road project nearby from
      #{item['fields']['locationde']}
      .  Go to http://http://www.improveourtulsa.com for more information
    TITLE
    
    {
      'id' => "#{item['recordid']}",
      'type' => 'Feature',
      'geometry' => item['fields']['geo_shape'],
      'properties' => {'title' => title,
                      'contact'=> item['fields']['emailconta'],
                      'phone'=> item['fields']['phoneconta']                      
                      }
    }
  end
  
  {'type' => 'FeatureCollection', 'features' => features}
end




