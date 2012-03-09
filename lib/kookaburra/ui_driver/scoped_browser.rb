class Kookaburra
  class UIDriver
    class ScopedBrowser
      def initialize(browser, scope)
        @browser = browser
        @scope = scope
      end

      def method_missing(name, *args, &block)
        super unless respond_to?(name)
        @browser.within(@scope) do
          @browser.send(name, *args, &block)
        end
      end

      def respond_to?(name)
        super || @browser.respond_to?(name)
      end
    end
  end
end
