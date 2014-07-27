require 'faraday'
require 'spy_glass/caches'

module SpyGlass
  module Clients
    class Base
      IDENTITY = ->(v){v}

      attr_accessor :path, :raw_path, :source, :cache,
                    :parser, :generator, :transform

      def initialize(attrs, &block)
        @path      = attrs.fetch(:path)
        @raw_path  = "#{path}/raw"
        @source    = attrs.fetch(:source)
        @cache     = attrs.fetch(:cache) { SpyGlass::Caches::Null.new }
        @parser    = attrs.fetch(:parser) { IDENTITY }
        @generator = attrs.fetch(:generator) { IDENTITY }
        @transform = block || IDENTITY
      end

      def cooked
        cache.fetch(path) do
          generator.call(transform.call(raw))
        end
      end

      def raw
        cache.fetch(source) do
          parser.call(get)
        end
      end

      def get
        response = connection.get

        # require 'debugger';debugger
        unless (200..299).include? response.status.to_i
          cache.clear
          raise 'failed request'
        end

        response.body
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
          build_connection(conn)
          conn.adapter Faraday.default_adapter
        end
      end
    end
  end
end
