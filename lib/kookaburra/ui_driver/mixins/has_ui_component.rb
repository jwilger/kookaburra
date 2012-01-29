require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/class/attribute'

module Kookaburra
  class UIDriver
    module HasUIComponent
      UIComponentNotFound = Class.new(StandardError)

      module ClassMethods
        def ui_component(component_name)
          self.ui_component_names << component_name

          define_method(component_name) do
            options = { :browser => browser }
            # TODO: memoize the following line?
            component_class(component_name).new(options)
          end
          private component_name

          define_method("has_#{component_name}?") do
            send(component_name).visible?
          end
        end
      end

      module InstanceMethods
        def ui_components
          ui_component_names.map { |name| self.send(name) }
        end

        def component_class(component_name)
          self.class.const_get(component_name.to_s.camelize)
        end
      end

      def self.included(receiver)
        receiver.class_attribute :ui_component_names
        receiver.ui_component_names = []

        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
  end
end
