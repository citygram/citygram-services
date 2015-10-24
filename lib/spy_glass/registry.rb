require 'active_support/inflector/inflections'
require 'active_support/time'
require 'action_view'
require 'core_ext/string'
require 'erb'
require 'json'
require 'logger'
require 'money'
require 'rack/utils'
require 'securerandom'
require 'sequel'
require 'spy_glass/client'

module SpyGlass
  DB = Sequel.connect(ENV.fetch('DATABASE_URL'))
  Log = Logger.new(STDOUT)
  DB.loggers << Log

  class RequestLog < Struct.new(:logger)
    Dataset = SpyGlass::DB[:http_requests]

    def call(name, starts, ends, _, env)
      url = env[:url]
      http_method = env[:method].to_s.upcase
      duration_in_seconds = ends - starts
      duration_in_milliseconds = (duration_in_seconds*1000).to_i

      logger.info '[%s] %s %s (%.3f s)' % [url.host, http_method, url.request_uri, duration_in_seconds]

      Dataset.insert(
        scheme:          url.scheme,
        userinfo:        url.userinfo,
        host:            url.host,
        port:            url.port,
        path:            url.path,
        query:           url.query,
        fragment:        url.fragment,
        method:          http_method,
        response_status: env[:status],
        duration:        duration_in_milliseconds,
        started_at:      starts,
      )
    rescue => e
      logger.error e.message
    end
  end

  module Utils
    extend ActionView::Helpers::TextHelper

    def self.point_srid_transform(x, y, _from, _to = 4326)
      geojson = SpyGlass::DB.dataset.with_sql(<<-SQL, x, y, _from, _to).get
        SELECT ST_AsGeoJSON(ST_Transform(ST_SetSRID(ST_MakePoint(?::numeric, ?::numeric), ?), ?)) AS latlng
      SQL

      JSON.parse(geojson)['coordinates']
    end

    def self.last_week_floating_timestamp
      7.days.ago.utc.iso8601.gsub(/Z$/,'')
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

ActiveSupport::Notifications.subscribe(
  /^request\.spyglass/,
  SpyGlass::RequestLog.new(SpyGlass::Log)
)

registry_dir = File.expand_path('../../spy_glass/registry/*.rb', __FILE__)
Dir[registry_dir].each { |file| require file }
