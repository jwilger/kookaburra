require 'rack/test'

module Kookaburra
  class APIDriver
    include Kookaburra::Assertion

    def initialize(opts)
      @app = opts.fetch(:app)
    end

    protected

    include Rack::Test::Methods

    attr_reader :app

    def raise_unless_status(expected_status, short_description)
      message = "%s failed (#{last_response.status})\n#{last_response.body}" % short_description
      raise message unless last_response.status == expected_status
    end

    ##### JSON Tools #####

    def post_as_json(short_description, path, data = {}, options = {})
      set_json_request_headers
      post path, data.to_json
      raise_unless_status options[:expected_status] || 201, short_description
    end

    def put_as_json(short_description, path, data = {}, options = {})
      set_json_request_headers
      put path, data.to_json
      raise_unless_status options[:expected_status] || 201, short_description
    end

    def get_as_json(short_description, path, data = {}, options = {})
      set_json_request_headers
      get path, data
      raise_unless_status options[:expected_status] || 200, short_description
    end

    def hash_from_response_json
      HashWithIndifferentAccess.new( JSON.parse(last_response.body) )
    end

    def set_json_request_headers
      header 'Content-Type', 'application/json'
      header 'Accept', 'application/json'
    end
  end
end
