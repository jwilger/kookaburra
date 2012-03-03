require 'kookaburra/exception_classes'
require 'rack/test'

class Kookaburra
  class RackDriver
    include Rack::Test::Methods

    attr_reader :app

    def initialize(rack_app)
      @app = rack_app
    end

    def post(path, data, headers = {}, env = {}, &block)
      set_headers(headers)
      super path, data, env, &block
      check_response_status!(:post, 201, path)
      last_response.body
    end

    private

    def check_response_status!(verb, expected_status, path)
      response_status = last_response.status
      response_body = last_response.body
      unless response_status == expected_status
        raise UnexpectedResponse, 
          "#{verb} to #{path} unexpectedly responded with an HTTP status of #{response_status}:\n" \
          + response_body
      end
    end

    def set_headers(headers)
      headers.each do |name, value|
        header name, value
      end
    end
  end
end
