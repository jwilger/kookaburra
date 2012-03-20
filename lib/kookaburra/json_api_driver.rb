require 'kookaburra/api_driver'
require 'delegate'
require 'active_support/json'

class Kookaburra
  class JsonApiDriver < SimpleDelegator
    J = ActiveSupport::JSON

    def initialize(options = {})
      api_driver = options[:api_driver] || APIDriver.new(:app_host => options[:app_host])
      api_driver.headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
      super(api_driver)
    end

    def post(path, data, *args)
      encoded_input = J.encode(data)
      output = super(path, encoded_input, *args)
      J.decode(output)
    end

    def put(path, data, *args)
      encoded_input = J.encode(data)
      output = super(path, encoded_input, *args)
      J.decode(output)
    end

    def get(path, *args)
      output = super
      J.decode(output)
    end

    def delete(path, *args)
      output = super
      J.decode(output)
    end
  end
end
