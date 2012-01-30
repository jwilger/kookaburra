module Kookaburra
  class UIDriver
    module HasBrowser
      Unexpected500 = Class.new(StandardError)

      # This will fail if the options hash does not include a value for the key :browser
      def initialize(options = {})
        super()
        @opts = options
      end

      def browser
        @browser ||= @opts.fetch(:browser)
      end

      def visit(*args)
        browser.visit *args
        no_500_error!
      end

      # Does not wait, so should only be used after failing a check
      # for being in the expected place.
      def no_500_error!
        return true if browser.all(:css, 'head title', :text => 'Internal Server Error').empty?
        sleep 30 if ENV['GIMME_CRAP']
        raise Unexpected500, browser.body
      end
    end
  end
end
