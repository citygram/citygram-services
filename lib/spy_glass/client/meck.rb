require 'json'
require 'spy_glass/client/base'

################################
# This client is manipulates
# headers in order to get JSON
# back from the Mecklenburg
# county api
################################

module SpyGlass
  module Client
    class Meck < Base
      DEFAULT_OPTIONS = {
        content_type: 'application/json',
        parser: ::JSON.method(:parse),
        generator: ::JSON.method(:pretty_generate)
      }

      def initialize(attrs, &block)
        super DEFAULT_OPTIONS.merge(attrs), &block
      end

      def build_connection(conn)
        # Hacks
        conn.headers.delete('Content-Type')
        conn.headers['Accept'] = '*/*'
      end
    end
  end
end
