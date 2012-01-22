module Kookaburra
  class GivenDriver
    attr_reader :api

    def initialize(opts)
      @api = opts.fetch(:api_driver)
    end
  end
end
