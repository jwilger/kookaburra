class Kookaburra
  class UIDriver
    # Classes that can contain reerences to {UIComponent} instances
    # (i.e. {UIDriver} and {UIDriver::UIComponent} subclasses are
    # extended by this module in order to set up those references.
    # {UIDriver} and {UIComponent} are already extended, so you
    # shouldn't need to do so elsewhere.
    #
    # Instances of the extending class must define a {#configuration}
    # method that returns the current Kookaburra::Configuration
    module HasUIComponents

      # Tells the extending UIDriver or UIComponent about your {UIComponent} subclasses.
      #
      # @param [Symbol] component_name Will create an instance method of this
      #   name that returns an instance of the component_class
      # @param [Class] component_class The {UIComponent} subclass that defines
      #   this component.
      # @param [Hash] options An extra options hash that will be passed
      #   to the {UIComponent} on initialization.
      def ui_component(component_name, component_class, options = {})
        define_method(component_name) do
          component_class.new(configuration, options)
        end
      end
    end
  end
end
