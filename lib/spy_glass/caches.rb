require 'active_support/cache'

module SpyGlass
  module Caches
    class Null < ActiveSupport::Cache::NullStore
    end

    class Memory < ActiveSupport::Cache::MemoryStore
      DEFAULT_OPTIONS = { expires_in: Integer(ENV['CACHE_TTL'] || 300) }

      def initialize(opts = {})
        super DEFAULT_OPTIONS.merge(opts)
      end
    end
  end
end
