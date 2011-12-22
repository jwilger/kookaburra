module Kookaburra
  class UIDriver
    class UIComponent
      include HasBrowser
      include HasFields
      include HasStrategies
      extend HasSubcomponents

      attr_reader :test_data

      # This will fail if the options hash does not include a value for the key :test_data
      def initialize(options = {})
        super
        @test_data = options.fetch(:test_data)
      end

      ##### Class macros #####
      def self.component_locator(locator)
        define_method(:component_locator) { locator }
      end

      def self.component_path(path)
        case path
        when Symbol
          alias_method :component_path, path
        else
          define_method(:component_path) { path }
        end
      end

      def self.path_id_regex(regex)
        define_method(:path_id_regex) { regex }
      end

      ##### Instance methods #####

      def visible!
        raise "#{self.class} not currently visible!" unless visible?
      end

      def visible?
        no_500_error!
        _visible?
      end

      def _visible?
        component_visible?
      end
      private :_visible?

      def show(opts = {})
        return if visible?
        raise "Subclass responsibility!" unless self.respond_to?(:component_path)
        path = component_path
        path << ( '?' + opts[:query_params].map{|kv| "%s=%s" % kv}.join('&') ) if opts[:query_params]
        visit path
      end

      def refresh
        visit component_path
      end

      def show!(opts = {})
        show opts
        visible!
      end

      def at_path?
        (component_path.to_a + alternate_paths.to_a).include?(browser.current_path)
      end

      def component_visible?
        at_path? && browser.has_css?(component_locator)
      end

      def alternate_paths
        []
      end

    private
      def id_from_path
        browser.current_path =~ path_id_regex
        $1.present? ? $1.to_i : nil
      end

      def fill_in(locator, options)
        in_component { browser.fill_in(locator, options) }
      end

      def click_on(locator)
        in_component { browser.find(locator).click }
      end

      def choose(locator)
        in_component { browser.choose(locator) }
      end

      def in_component(&blk)
        browser.within(component_locator, &blk)
      end
    end
  end
end
