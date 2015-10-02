require 'faraday'
require 'sinatra'
require 'json'

get '/tulsa-fire-dispatch' do
  
  url = URI('https://www.cityoftulsa.org/cot/opendata/tfd_dispatch.jsn')
  
  connection = Faraday.new(url: url.to_s)

  response = connection.get

  collection = JSON.parse(response.body)

  features = collection['Incidents']['Incident'].map do |record|
    
    title = <<-TITLE 
      The Tulsa Fire Department has responded to a #{record['Problem']} 
      at #{record['Address']}.
      See all the dispatches near you at https://www.citygram.org/tulsa
    TITLE
    {
      'id' => record['IncidentNumber'],
      'type' => 'Feature',
      'title' => title,
      'geometry' => {
        'type' => 'Point',
        'coordinates' => [
          record['Longitude'].to_f,
          record['Latitude'].to_f
        ]
      }
    }
  end

  content_type :json
  JSON.pretty_generate('type' => 'FeatureCollection', 'features' => features)
end

