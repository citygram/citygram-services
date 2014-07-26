require 'spy_glass/clients/json'

module SpyGlass
  module Clients
    class Socrata < SpyGlass::Clients::JSON
      MissingAuthToken = Class.new StandardError

      def intialize(attrs, &block)
        @auth_token = attrs[:auth_token] || ENV['SOCRATA_APP_TOKEN'] || raise(MissingAuthToken)
        super attrs, &block
      end

      def build_connection(conn)
        super(conn)
        conn.headers['X-App-Token'] = @auth_token
      end
    end
  end
end
