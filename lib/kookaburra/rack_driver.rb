require 'kookaburra/exceptions'
require 'rack/test'

class Kookaburra
  # This is a small wrapper around the `Rack::Test::Methods` which is used by
  # your {APIDriver}.
  class RackDriver
    include Rack::Test::Methods

    # This is the Rack application instance
    attr_reader :app

    # @param [#call] rack_app The Rack application object for the application under test
    def initialize(rack_app)
      @app = rack_app
    end

    # Sends a POST request to the application.
    #
    # Similar to `Rack::Test::Methods#post` except that it adds more convenient
    # access to setting request headers, it raises an exception if the response
    # status is not 201, and it returns the response body.
    #
    # @param [String] path The path portion of the URI to request from the
    #   application
    # @param [Object] params The request params or body
    # @param [Hash] headers A hash of any additional HTTP headers to be set on
    #   the request.
    # @param [Hash] env Additional environment variables that should be present
    #   on the request.
    # @yield [Rack::Response] Yields the last response to the block if a
    #   block is given.
    def post(path, params = {}, headers = {}, env = {}, &block)
      set_headers(headers)
      super path, params, env, &block
      check_response_status!(:post, 201, path)
      last_response.body
    end

    # Sends a PUT request to the application.
    #
    # Similar to `Rack::Test::Methods#put` except that it adds more convenient
    # access to setting request headers, it raises an exception if the response
    # status is not 200, and it returns the response body.
    #
    # @param [String] path The path portion of the URI to request from the
    #   application
    # @param [Object] params The request params or body
    # @param [Hash] headers A hash of any additional HTTP headers to be set on
    #   the request.
    # @param [Hash] env Additional environment variables that should be present
    #   on the request.
    # @yield [Rack::Response] Yields the last response to the block if a
    #   block is given.
    def put(path, params = {}, headers = {}, env = {}, &block)
      set_headers(headers)
      super path, params, env, &block
      check_response_status!(:put, 200, path)
      last_response.body
    end

    # Sends a GET request to the application.
    #
    # Similar to `Rack::Test::Methods#get` except that it adds more convenient
    # access to setting request headers, it raises an exception if the response
    # status is not 200, and it returns the response body.
    #
    # @param [String] path The path portion of the URI to request from the
    #   application
    # @param [Object] params The request params or body
    # @param [Hash] headers A hash of any additional HTTP headers to be set on
    #   the request.
    # @param [Hash] env Additional environment variables that should be present
    #   on the request.
    # @yield [Rack::Response] Yields the last response to the block if a
    #   block is given.
    def get(path, params = {}, headers = {}, env = {}, &block)
      set_headers(headers)
      super path, params, env, &block
      check_response_status!(:get, 200, path)
      last_response.body
    end

    private

    def check_response_status!(verb, expected_status, path)
      actual_status = response_status
      unless actual_status == expected_status
        raise UnexpectedResponse, 
          "#{verb} to #{path} unexpectedly responded with an HTTP status of #{actual_status}:\n" \
          + response_body
      end
    end

    def response_status
      last_response.status
    end

    def response_body
      last_response.body
    end

    def set_headers(headers)
      headers.each do |name, value|
        header name, value
      end
    end
  end
end
