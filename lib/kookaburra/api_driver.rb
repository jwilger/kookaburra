require 'restclient'
require 'active_support/core_ext/object/to_query'
require 'kookaburra/exceptions'

class Kookaburra
  # Communicate with a Web Services API
  #
  # You will create a subclass of `APIDriver` in your testing
  # implementation to be used with you subclass of
  # `Kookaburra::GivenDriver`. While the `GivenDriver` implements the
  # "business domain" DSL for setting up your application state, the
  # `APIDriver` maps discreet operations to your application's web
  # service API and can (optionally) handle encoding input data and
  # decoding response bodies to and from your preferred serialization
  # format.
  class APIDriver
    class << self
      # Serializes input data
      #
      # If specified, any input data provided to `APIDriver#post`,
      # `APIDriver#put` or `APIDriver#request` will be processed through
      # this function prior to being sent to the HTTP server.
      #
      # @yieldparam data [Object] The data parameter that was passed to
      #             the request method
      # @yieldreturn [String] The text to be used as the request body
      #
      # @example
      #   class MyAPIDriver < Kookaburra::APIDriver
      #     encode_with { |data| JSON.dump(data) }
      #     # ...
      #   end
      def encode_with(&block)
        define_method(:encode) do |data|
          return if data.nil?
          block.call(data)
        end
      end

      # Deserialize response body
      #
      # If specified, the response bodies of all requests made using
      # this `APIDriver` will be processed through this function prior
      # to being returned.
      #
      # @yieldparam data [String] The response body sent by the HTTP
      #             server
      #
      # @yieldreturn [Object] The result of parsing the response body
      #              through this function
      #
      # @example
      #   class MyAPIDriver < Kookaburra::APIDriver
      #     decode_with { |data| JSON.parse(data) }
      #     # ...
      #   end
      def decode_with(&block)
        define_method(:decode) do |data|
          block.call(data)
        end
      end

      # Set custom HTTP headers
      #
      # Can be called multiple times to set HTTP headers that will be
      # provided with every request made by the `APIDriver`.
      #
      # @param [String] name The name of the header, e.g. 'Content-Type'
      # @param [String] value The value to which the header is set
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

      # Used to retrieve the list of headers within the instance. Not
      # intended to be used elsewhere.
      #
      # @private
      def headers
        @headers ||= {}
      end
    end

    # Create a new `APIDriver` instance
    #
    # @param [Kookaburra::Configuration] configuration
    # @param [RestClient] http_client (optional) Generally only
    #        overriden when testing Kookaburra itself
    def initialize(configuration, http_client = RestClient)
      @configuration = configuration
      @http_client = http_client
    end

    # Convenience method to make a POST request
    #
    # @see APIDriver#request
    def post(path, data)
      request(:post, path, data)
    end

    # Convenience method to make a PUT request
    #
    # @see APIDriver#request
    def put(path, data)
      request(:put, path, data)
    end

    # Convenience method to make a GET request
    #
    # @see APIDriver#request
    def get(path, data = nil)
      path = add_querystring_to_path(path, data)
      request(:get, path)
    end

    # Convenience method to make a DELETE request
    #
    # @see APIDriver#request
    def delete(path, data = nil)
      path = add_querystring_to_path(path, data)
      request(:delete, path)
    end

    # Make an HTTP request
    #
    # If you need to make a request other than the typical GET, POST,
    # PUT and DELETE, you can use this method directly.
    #
    # This *will* follow redirects when the server's response code is in
    # the 3XX range. If the response is a 303, the request will be
    # transformed into a GET request.
    #
    # @see APIDriver.encode_with
    # @see APIDriver.decode_with
    # @see APIDriver.header
    # @see APIDriver#get
    # @see APIDriver#post
    # @see APIDriver#put
    # @see APIDriver#delete
    #
    # @param [Symbol] method The HTTP verb to use with the request
    # @param [String] path The path to request. Will be joined with the
    #        `Kookaburra::Configuration#app_host` setting to build the
    #        URL unless a full URL is specified here.
    # @param [Object] data The data to be posted in the request body. If
    #        an encoder was specified, this can be any type of object as
    #        long as the encoder can serialize it into a String. If no
    #        encoder was specified, then this can be one of:
    #
    #        * a String - will be passed as is
    #        * a Hash - will be encoded as normal HTTP form params
    #        * a Hash containing references to one or more Files - will
    #          set the content type to multipart/form-data
    #
    # @return [Object] The response body returned by the server. If a
    #         decoder was specified, this will return the result of
    #         parsing the response body through the decoder function.
    #
    # @raise [Kookaburra::UnexpectedResponse] Raised if the HTTP
    #        response received is not in the 2XX-3XX range.
    def request(method, path, data = nil)
      data = encode(data)
      response = @http_client.send(method, url_for(path), *[data, headers].compact)
      decode(response.body)
    rescue RestClient::Exception => e
      raise_unexpected_response(e)
    end

    private

    def add_querystring_to_path(path, data)
      return path if data.nil?
      "#{path}?#{data.to_query}"
    end

    def headers
      self.class.headers
    end

    def url_for(path)
      URI.join(base_url, path).to_s
    end

    def base_url
      @configuration.app_host
    end

    def encode(data)
      data
    end

    def decode(data)
      data
    end

    def raise_unexpected_response(exception)
      message = <<-END
      Unexpected response from server: #{exception.message}

      #{exception.http_body}
      END
      new_exception = UnexpectedResponse.new(message)
      new_exception.set_backtrace(exception.backtrace)
      raise new_exception
    end
  end
end
