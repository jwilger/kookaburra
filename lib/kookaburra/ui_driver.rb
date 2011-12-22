base_path = File.expand_path(File.join(File.dirname(__FILE__), *%w[ui_driver]))
%w[has_browser has_fields has_strategies has_subcomponents has_ui_component ui_component].each do |file|
  require File.join(base_path, file)
end


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
