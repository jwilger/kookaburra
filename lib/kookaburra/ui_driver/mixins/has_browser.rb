module Kookaburra
  class UIDriver
    module HasBrowser
      Unexpected500 = Class.new(StandardError)

      # This will fail if the options hash does not include a value for the key :browser
      def initialize(options = {})
        super()
        @browserish = options.fetch(:browser)
      end

      def browser
        @browserish
      end

      def visit(*args)
        browser.visit *args
        no_500_error!
      end

      def no_500_error!
        if browser.has_css?('head title', :text => 'Internal Server Error')
          sleep 30 if ENV['GIMME_CRAP']
          raise Unexpected500
        end
      end
    end
  end
end
