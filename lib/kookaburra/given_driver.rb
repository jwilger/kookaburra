module Kookaburra
  class GivenDriver
    include Kookaburra::Assertion

    attr_reader :api
    attr_reader :test_data

    def initialize(opts)
      @api = opts.fetch(:api_driver)
      @test_data = opts.fetch(:test_data)
    end
  end
end
