module Kookaburra
  class UIDriver
    module HasUIComponent
      module ClassMethods
        def ui_component(component_name)
          component_class = component_name.to_s.camelize.constantize

          self.ui_component_names << component_name

          define_method(component_name) do
            options = { :browser => browser, :test_data => test_data }
            # TODO: memoize the following line?
            component_class.new(options)
          end

          define_method("has_#{component_name}?") do
            send(component_name).visible?
          end
        end
      end

      module InstanceMethods
        def ui_components
          ui_component_names.map { |name| self.send(name) }
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
