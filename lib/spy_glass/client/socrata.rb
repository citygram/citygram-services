require 'spy_glass/client/json'

module SpyGlass
  module Client
    class Socrata < SpyGlass::Client::JSON
      MissingAuthToken = Class.new StandardError
      ApiError = Class.new StandardError

      def initialize(attrs, &block)
        @auth_token = attrs[:auth_token] || ENV['SOCRATA_APP_TOKEN'] || raise(MissingAuthToken)
        super attrs, &wrap_api_errors(&block)
      end

      def build_connection(conn)
        super(conn)
        conn.headers['X-App-Token'] = @auth_token
      end

      private

      def wrap_api_errors(&transform)
        -> (response) {
          if response.is_a?(Hash) && response["error"]
            raise(ApiError.new(response["message"]))
          end
          transform.call(response)
        }
      end
    end
  end
end
