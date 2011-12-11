module Kookaburra
  class APIDriver
    include Rack::Test::Methods
    attr_reader :app, :test_data
    protected :app, :test_data

    # Pattern:
    # - Get some data from test_data.factory
    # - Post it to the API
    # - Remember the response in test_data

    def initialize(opts)
      @app       = opts.fetch(:app)
      @test_data = opts.fetch(:test_data)
    end

  protected

    def post_as_json(short_description, path, data = {})
      header 'Content-Type', 'application/json'
      header 'Accept', 'application/json'
      post path, data.to_json
      raise_unless_created short_description
    end

    def put_as_json(short_description, path, data = {})
      header 'Content-Type', 'application/json'
      header 'Accept', 'application/json'
      put path, data.to_json
      raise_unless_created short_description
    end

    def hash_from_response_json
      HashWithIndifferentAccess.new( JSON.parse(last_response.body))
    end

    def raise_unless_created(short_description)
      message = "%s creation failed (#{last_response.status})\n#{last_response.body}" % short_description
      raise message unless last_response.status == 201
    end
  end
end
