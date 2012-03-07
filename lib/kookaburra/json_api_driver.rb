require 'kookaburra/dependency_accessor'
require 'kookaburra/rack_driver'
require 'active_support/json'

class Kookaburra
  class JsonApiDriver
    J = ActiveSupport::JSON

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
      response = @app_driver.post(path, J.encode(data), json_request_headers)
      J.decode(response).symbolize_keys
    end
  end
end
