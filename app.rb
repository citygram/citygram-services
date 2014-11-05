require 'dotenv';Dotenv.load
require 'sinatra'

$: << './lib'
require 'spy_glass'

configure :production do
  require 'newrelic_rpm'
  require 'rack/ssl'
  use Rack::SSL
end

SpyGlass::Registry.each do |glass|
  get(glass.path) do
    content_type glass.content_type
    glass.cooked
  end

  get(glass.raw_path) do
    content_type glass.content_type
    glass.raw
  end
end

services = JSON.pretty_generate(services: SpyGlass::Registry.map(&:to_h))

get '/services' do
  content_type :json
  services
end

get '/' do
  erb :index
end

def format_leaf_collection(geo_json)
  esri_formatted = JSON.parse(geo_json)

  features = esri_formatted['features'].map do |feature|
    properties = feature['attributes']
    title = "Hello! Leaf collection status in your area is now '#{properties['Status']}'."
    title += " Collection dates are #{properties['Dates']}" if properties['Dates']
    {
      type: "Feature",
      id: properties['OBJECTID'],
      properties: {
        title: title
      },
      geometry: {
        type: "Polygon",
        coordinates: feature['geometry']['rings']
      }
    }
  end

  {
    type: "FeatureCollection",
    features: features
  }.to_json
end

get '/lexington-leaf-collection' do
  content_type :json
  source = 'http://services1.arcgis.com/Mg7DLdfYcSWIaDnu/ArcGIS/rest/services/Leaf_Collection/FeatureServer/1/query?where=++objectid%3Dobjectid&objectIds=&time=&geometry=&geometryType=esriGeometryEnvelope&inSR=&spatialRel=esriSpatialRelIntersects&distance=&units=esriSRUnit_Meter&outFields=*&returnGeometry=true&maxAllowableOffset=&geometryPrecision=&outSR=4326&returnIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&resultOffset=0&resultRecordCount=&returnZ=false&returnM=false&f=pjson&token='
  connection = Faraday.new(url: source) do |conn|
    conn.headers['Content-Type'] = content_type
    conn.adapter Faraday.default_adapter
  end
  format_leaf_collection connection.get.body
end
