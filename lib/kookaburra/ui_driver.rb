require 'kookaburra/ui_driver/mixins/has_browser'
require 'kookaburra/ui_driver/mixins/has_ui_component'

module Kookaburra
  class UIDriver
    include HasBrowser
    include HasUIComponent

    def test_data
      @test_data ||= @opts.fetch(:test_data)
    end

    def initialize(opts = {})
      super
      @opts = opts
    end

    def navigate_to(component_id, parameters = {})
      if ui_component_names.include?(component_id)
        self.send(component_id).show!(parameters)
      else
        raise UIComponentNotFound, "The #{component_id} component is not registered"
      end
    end
  end
end
