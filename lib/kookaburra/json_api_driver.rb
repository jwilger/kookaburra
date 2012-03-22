require 'kookaburra/api_driver'
require 'delegate'
require 'active_support/json'

class Kookaburra
  class JsonApiDriver < SimpleDelegator
    def initialize(options = {})
      api_driver = options[:api_driver] || APIDriver.new(:app_host => options[:app_host])
      api_driver.headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
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
