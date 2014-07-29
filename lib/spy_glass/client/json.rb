require 'json'
require 'spy_glass/client/base'

module SpyGlass
  module Client
    class JSON < Base
      DEFAULT_OPTIONS = {
        parser: ::JSON.method(:parse),
        generator: ::JSON.method(:pretty_generate)
      }

      def initialize(attrs, &block)
        super DEFAULT_OPTIONS.merge(attrs), &block
      end

      def build_connection(conn)
        conn.headers['Content-Type'] = 'application/json'
      end
    end
  end
end
