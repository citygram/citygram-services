require 'json'
require 'spy_glass/client/base'

module SpyGlass
  module Client
    class JSON < Base
      DEFAULT_OPTIONS = {
        content_type: 'application/json',
        parser: ::JSON.method(:parse),
        generator: ::JSON.method(:pretty_generate)
      }

      def initialize(attrs, &block)
        super DEFAULT_OPTIONS.merge(attrs), &block
      end
    end
  end
end
