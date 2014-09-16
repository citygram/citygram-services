require 'active_support/inflector/inflections'
require 'active_support/time'
require 'action_view'
require 'core_ext/string'
require 'erb'
require 'json'
require 'logger'
require 'money'
require 'rack/utils'
require 'sequel'
require 'spy_glass/client'

module SpyGlass
  module Utils
    DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
    DB.loggers << Logger.new(STDOUT)

    def self.point_srid_transform(x, y, _from, _to = 4326)
      geojson = DB.dataset.with_sql(<<-SQL, x, y, _from, _to).get
        SELECT ST_AsGeoJSON(ST_Transform(ST_SetSRID(ST_MakePoint(?::numeric, ?::numeric), ?), ?)) AS latlng
      SQL

      JSON.parse(geojson)['coordinates']
    end
  end

  Registry = []
  Salutations = [
    'Hi!',
    'Hello!',
    'Salutations!',
    'YO!',
    'Hi there.',
    'Hey.',
    'Hola.',
    'Ahoy!',
    'Aloha!',
    'Ciao.',
    'Hi :)',
    'Good day!',
    'Greetings!',
    'Look!'
  ].cycle
end

registry_dir = File.expand_path('../../spy_glass/registry/*.rb', __FILE__)
Dir[registry_dir].each { |file| require file } 
