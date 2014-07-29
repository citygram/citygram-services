require 'faraday'
require 'faraday_middleware'
require 'spy_glass/cache'

module SpyGlass
  module Client
    class Base
      IDENTITY = ->(v){v}

      attr_accessor :path, :raw_path, :source, :cache,
                    :content_type, :parser, :generator, :transform

      def initialize(attrs, &block)
        @path         = attrs.fetch(:path)
        @raw_path     = "#{path}/raw"
        @source       = attrs.fetch(:source)
        @content_type = attrs.fetch(:content_type, 'text/html')
        @cache        = attrs.fetch(:cache) { SpyGlass::Cache::Null.new }
        @parser       = attrs.fetch(:parser, IDENTITY)
        @generator    = attrs.fetch(:generator, IDENTITY)
        @transform    = block || IDENTITY
      end

      def cooked
        cache.fetch(path) do
          generator.(transform.(parser.(raw)))
        end
      end

      def raw
        connection.get.body
      end

      def build_connection(conn)
        # handled by subclass
      end

      def to_h
        {
          path: path,
          cache_ttl: cache.options[:expires_in],
          source: source,
        }
      end

      private

      def connection
        @connection ||= Faraday.new(url: source) do |conn|
          conn.headers['Content-Type'] = content_type
          conn.response :caching, cache
          build_connection(conn)
          conn.adapter Faraday.default_adapter
        end
      end
    end
  end
end
