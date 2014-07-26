require 'dotenv';Dotenv.load
require 'sinatra'

$: << './lib'
require 'spy_glass'

SpyGlass::Registry.each do |glass|
  get(glass.path) do
    content_type :json
    glass.cooked
  end

  get(glass.raw_path) do
    content_type :json
    glass.generator.call(glass.raw)
  end
end

get '/' do
  erb :index
end
