require 'kookaburra/exceptions'
require 'delegate'
require 'patron'

class Kookaburra
  class APIDriver < SimpleDelegator
    class << self
      # Encode input data
      #
      # Input data for `#post` and `#put` are processed through this
      # block prior to being transmitted.
      #
      # @yieldparam data [Object] the data object as passed into the
      #             call to `APIDriver#post` or `APIDriver#put`
      #
      # @yieldreturn [String] The string that will be used as the body
      #              of the request
      #
      # @example
      #   require 'json'
      #
      #   class MyAPIDriver < Kookaburra::APIDriver
      #     encode_with { |data| JSON.dump(data) }
      #     # ...
      #   end
      def encode_with(&block)
        define_method(:encode, &block)
      end

      # Decode response bodies
      #
      # All response bodies will be processed through this block prior
      # to being returned.
      #
      # @yieldparam data [String] the response body returned by the
      #             server
      #
      # @yieldreturn [Object] whatever type of object you want the data
      #              to be parsed to
      #
      # @example
      #   require 'json'
      #
      #   class MyAPIDriver < Kookaburra::APIDriver
      #     decode_with { |data| JSON.parse(data) }
      #     # ...
      #   end
      def decode_with(&block)
        define_method(:decode, &block)
      end

      # Sets an HTTP header that will be added to every request
      #
      # @param [String] name
      # @param [String] value
      #
      # @example
      #   class MyAPIDriver < Kookaburra::APIDriver
      #     header 'Content-Type', 'application/json'
      #     header 'Accept', 'application/json'
      #     # ...
      #   end
      def header(name, value)
        headers[name] = value
      end

      # @private
      #
      # Used to access the headers in `APIDriver#initialize`
      def headers
        @headers ||= {}
      end
    end

    # Wraps `http_client` in a `SimpleDelegator` that causes request methods to
    # either return the response body or raise an exception on an unexpected
    # response status code.
    #
    # @param [Kookaburra::Configuration] configuration
    # @param [Patron::Session] http_client
    def initialize(configuration, http_client = Patron::Session.new)
      http_client.base_url = configuration.app_host
      headers = self.class.headers
      http_client.headers.merge!(self.class.headers) if headers.any?
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
      data = data.nil? ? nil : encode(data)
      args = [type, path, data, options].compact
      response = __getobj__.send(*args)

      check_response_status!(type, response, options)
      decode(response.body)
    end

    def check_response_status!(request_type, response, options)
      verb = request_type.to_s.upcase
      expected_status = options[:expected_response_status] || (200..299)
      unless expected_status === response.status
        raise UnexpectedResponse, "#{verb} to #{response.url} responded with " \
          + "#{response.status} status, not #{expected_status} as expected\n\n" \
          + response.body
      end
    end

    def encode(data)
      data
    end
    alias :decode :encode
  end
end
