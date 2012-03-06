require 'kookaburra/dependency_accessor'
require 'kookaburra/rack_driver'
require 'active_support/json'

class Kookaburra
  class JsonApiDriver
    def initialize(app_driver)
      @app_driver = app_driver
    end

    private

    def authorize(username, password)
      @app_driver.authorize(username, password)
    end

    def post(path, data)
      json_request_headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
      response = @app_driver.post(path, encode(data), json_request_headers)
      decode(response)
    end

    def encode(data)
      ActiveSupport::JSON.encode(data)
    end

    def decode(data)
      ActiveSupport::JSON.decode(data).symbolize_keys
    end
  end
end
