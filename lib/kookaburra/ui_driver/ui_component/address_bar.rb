require 'kookaburra/ui_driver/ui_component'

class Kookaburra
  class UIDriver
    class UIComponent
      # This represents the browser's address bar, so that you can tell your
      # tests to explicitly visit a URL.
      class AddressBar < UIComponent
        # Causes the browser to explicitly navigate to the given url.
        #
        # @param [String, #url] addressable Can be either a URL string or an
        # object that responds to #url and returns a URL string
        def go_to(addressable)
          if addressable.respond_to?(:url)
            browser.visit(addressable.url)
          else
            browser.visit(addressable.to_s)
          end
          detect_server_error!
        end
      end
    end
  end
end
