require 'dotenv';Dotenv.load
require 'sinatra'

$: << './lib'
require 'spy_glass'

configure :production do
  require 'newrelic_rpm'
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
