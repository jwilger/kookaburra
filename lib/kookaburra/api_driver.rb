require 'kookaburra/exceptions'
require 'delegate'
require 'patron'

class Kookaburra
  class APIDriver < SimpleDelegator
    # Wraps `http_client` in a `SimpleDelegator` that causes request methods to
    # either return the response body or raise an exception on an unexpected
    # response status code.
    #
    # @param [Kookaburra::Configuration] configuration
    # @param [Patron::Session] http_client
    def initialize(configuration, http_client = Patron::Session.new)
      http_client.base_url = configuration.app_host
      super(http_client)
    end

    # Makes a POST request via the `:http_client`
    #
    # @param [String] path The path to request (e.g. "/foo")
    # @param [Hash, String] data The post data. If a Hash is provided, it will
    #   be converted to an 'application/x-www-form-urlencoded' post body.
    # @option options [Integer] :expected_response_status (201) The HTTP status
    #   code that you expect the server to respond with.
    # @raise [Kookaburra::UnexpectedResponse] raised if the HTTP status of the
    #   response does not match the `:expected_response_status`
    def post(path, data, options = {})
      request(:post, path, options, data)
    end

    # Makes a PUT request via the `:http_client`
    #
    # @param [String] path The path to request (e.g. "/foo")
    # @param [Hash, String] data The post data. If a Hash is provided, it will
    #   be converted to an 'application/x-www-form-urlencoded' post body.
    # @option options [Integer] :expected_response_status (201) The HTTP status
    #   code that you expect the server to respond with.
    # @raise [Kookaburra::UnexpectedResponse] raised if the HTTP status of the
    #   response does not match the `:expected_response_status`
    def put(path, data, options = {})
      request(:put, path, options, data)
    end

    # Makes a GET request via the `:http_client`
    #
    # @param [String] path The path to request (e.g. "/foo")
    # @option options [Integer] :expected_response_status (201) The HTTP status
    #   code that you expect the server to respond with.
    # @raise [Kookaburra::UnexpectedResponse] raised if the HTTP status of the
    #   response does not match the `:expected_response_status`
    def get(path, options = {})
      request(:get, path, options)
    end

    # Makes a DELETE request via the `:http_client`
    #
    # @param [String] path The path to request (e.g. "/foo")
    # @option options [Integer] :expected_response_status (201) The HTTP status
    #   code that you expect the server to respond with.
    # @raise [Kookaburra::UnexpectedResponse] raised if the HTTP status of the
    #   response does not match the `:expected_response_status`
    def delete(path, options = {})
      request(:delete, path, options)
    end

    private

    def request(type, path, options = {}, data = nil)
      # don't send a data argument if it's not passed in, because some methods
      # on target object may not have the proper arity (i.e. #get and #delete).
      if path.nil?
        raise ArgumentError, "You must specify a request URL, but it was nil."
      end
      args = [type, path, data, options].compact
      response = __getobj__.send(*args)

      check_response_status!(type, response, options)
      response.body
    end

    def check_response_status!(request_type, response, options)
      verb, default_status = verb_map[request_type]
      expected_status = options[:expected_response_status] || default_status
      unless expected_status == response.status
        raise UnexpectedResponse.new(response.status), "#{verb} to #{response.url} responded with " \
          + "#{response.status} status, not #{expected_status} as expected\n\n" \
          + response.body
      end
    end

    def verb_map 
      {
        :get => ['GET', 200],
        :post => ['POST', 201],
        :put => ['PUT', 200],
        :delete => ['DELETE', 200]
      }
    end
  end
end
