require 'kookaburra/dependency_accessor'
require 'kookaburra/rack_driver'
require 'kookaburra/api_driver'
require 'active_support/json'

class Kookaburra
  # Use this for your APIDriver base class if your application implements a JSON
  # webservice API. The JsonApiDriver abstracts away the details of translating
  # JSON <-> Ruby and setting the necessary request headers.
  #
  # @example Create a widget via API
  #   module MyApp
  #     module Kookaburra
  #       class APIDriver < ::Kookaburra::JsonApiDriver
  #         def create_widget(data)
  #           post '/widgets', data
  #         end
  #       end
  #     end
  #   end
  #
  # @note This implementation uses `ActiveSupport::JSON` to handle JSON
  #   translation.
  class JsonApiDriver < APIDriver
    # @private
    J = ActiveSupport::JSON

    # @param [Kookaburra::RackDriver] app_driver
    def initialize(app_driver)
      @app_driver = app_driver
    end

    protected

    # Sets headers for HTTP Basic authentication if your application requires
    # it.
    #
    # @example
    #   def create_widget(data)
    #     authorize('api_user', 'api_password')
    #     post '/widgets', data
    #   end
    #
    # @param [String] username
    # @param [String] password
    def authorize(username, password)
      @app_driver.authorize(username, password)
    end

    # Make a JSON post request to the server
    #
    # @param [String] path The path portion of the URI that should be requested
    # @param [Hash] data The data that should be translated into a JSON post
    #   body for the request.
    #
    # @return [Hash] The decoded response from the server
    #
    # @example
    #   # in your JsonApiDriver subclass
    #   def create_widget(data)
    #     post '/widgets', data
    #   end
    #
    #   # in a method within your GivenDriver
    #   api.create_widget(:name => 'Foo')
    #   #=> {:id => 1, :name => 'Foo', :description => ''}
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
