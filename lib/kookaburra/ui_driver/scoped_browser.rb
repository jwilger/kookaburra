class Kookaburra
  class UIDriver
    # Wraps a Kookaburra `browser` object and changes all method calls
    # to that object so that they are scoped within the specified
    # {#component_locator}.
    class ScopedBrowser < BasicObject

      # @param [Object] browser The browser driver object used by
      #   Kookaburra to drive the browser session
      # @param [Proc] component_locator A Proc that will return the CSS
      #   locator used to identify the HTML element within which all
      #   calls to this object should be scoped. (A Proc is used rather
      #   than a string, because it is possible that the object creating
      #   this {ScopedBrowser} will not know the correct string at the
      #   time this object is created.)
      def initialize(browser, component_locator)
        @browser = browser
        @component_locator = component_locator
      end

      private

      def component_locator
        @component_locator.call
      end

      def method_missing(name, *args, &blk)
        @browser.within(component_locator) do
          @browser.send(name, *args, &blk)
        end
      end
    end
  end
end
