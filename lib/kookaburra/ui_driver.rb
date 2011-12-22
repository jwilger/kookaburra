module Kookaburra
  class UIDriver
    include HasBrowser
    include HasUIComponent

    attr_reader :test_data

    def initialize(opts = {})
      super
      @test_data = opts.fetch(:test_data)
    end
  end
end
