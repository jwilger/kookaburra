require 'kookaburra/api_driver'
require 'delegate'
require 'active_support/json'

class Kookaburra
  # Delegates all methods (by default) to and instance of
  # {Kookaburra::APIDriver}.
  #
  # Expects the application's API to accept and respond with JSON formatted
  # data. All methods will decode the response body using
  # `ActiveSupport::JSON.decode`. Methods that take input data ({#post} and
  # {#put}) will encode the post data using `ActiveSupport::JSON.encode`.
  class JsonApiDriver < SimpleDelegator
    #
    # Sets both the "Content-Type" and "Accept" headers to "application/json".
    #
    # @option options [Kookaburra::APIDriver] :api_driver (Kookaburra::APIDriver.new)
    #   The APIDriver instance to be delegated to. Changing this is probably
    #   only useful for testing.
    def initialize(options = {})
      api_driver = options[:api_driver] || APIDriver.new(:app_host => options[:app_host])
      api_driver.headers.merge!(
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      )
      super(api_driver)
    end

    def post(path, data, *args)
      request(:post, path, data, *args)
    end

    def put(path, data, *args)
      request(:put, path, data, *args)
    end

    def get(path, *args)
      request(:get, path, nil, *args)
    end

    def delete(path, *args)
      request(:delete, path, nil, *args)
    end

    private

    def request(type, path, data = nil, *args)
      # don't want to send data to methods that don't accept it
      args = [path, encode(data), args].flatten.compact
      output = __getobj__.send(type, *args)

      decode(output)
    end

    def encode(data)
      ActiveSupport::JSON.encode(data) unless data.nil?
    end

    def decode(data)
      ActiveSupport::JSON.decode(data)
    end
  end
end
