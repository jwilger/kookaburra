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
      
        def current_component
          # TODO: This will fail if we ever add a component for something that's visible on every page
          # It might make sense to add some sort of priority to components,
          # or maybe some additional selector so we can say current_submittable_component... just an idea.
          ui_components.detect(&:visible?).tap do |component|
            raise "There are no visible components!" if component.nil?
          end
        end
      end

      def self.included(receiver)
        receiver.class_inheritable_accessor :ui_component_names
        receiver.ui_component_names = []

        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
  end
end
