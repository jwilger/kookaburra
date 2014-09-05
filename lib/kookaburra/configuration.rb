require 'ostruct'
require 'delegate'
require 'kookaburra/dependency_accessor'

class Kookaburra
  # Provides access to the configuration data used throughout Kookaburra
  class Configuration
    extend DependencyAccessor

    # The class to use as your APIDriver
    #
    # @attribute [rw] api_driver_class
    # @raise [Kookaburra::ConfigurationError] if you try to read this attribute
    #   without it having been set
    dependency_accessor :api_driver_class

    # The class to use as your UIDriver
    #
    # @attribute [rw] ui_driver_class
    # @raise [Kookaburra::ConfigurationError] if you try to read this attribute
    #   without it having been set
    dependency_accessor :ui_driver_class

    # This object is used by {Kookaburra::UIDriver::UIComponent} to interface
    # with the web browser. Typically it should be an instance of
    # {Capybara::Session}
    #
    # @attribute [rw] browser
    # @raise [Kookaburra::ConfigurationError] if you try to read this attribute
    #   without it having been set
    dependency_accessor :browser

    # This is the root URL of your running application, including the port
    # number if necessary. (e.g. "http://my.example.com:12345")
    #
    # @attribute [rw] app_host
    # @raise [Kookaburra::ConfigurationError] if you try to read this attribute
    #   without it having been set
    dependency_accessor :app_host

    # This is the {Kookaburra::MentalModel} that is shared between your
    # APIDriver and your UIDriver. This attribute is managed by {Kookaburra},
    # so you shouldn't need to change it yourself.
    #
    # @attribute [rw] mental_model
    # @raise [Kookaburra::ConfigurationError] if you try to read this attribute
    #   without it having been set
    dependency_accessor :mental_model

    # This is the logger to which Kookaburra will send various messages
    # about its operation. This would generally be used to allow
    # UIDriver subclasses to provide detailed failure information.
    #
    # @attribute [rw] logger
    dependency_accessor :logger

    def application(app_name, &block)
      TestHelpers.module_eval do
        define_method(app_name) {
          @applications ||= Hash.new do |h,k|
            h[k] = Kookaburra.new
          end
          @applications[app_name]
        }
      end
      block.call(self)
    end

    # Specify a function that can be used to determine if a server error has
    # occured within your application.
    #
    # If the function returns `true`, then Kookaburra will assume that the
    # application has responded with an error.
    #
    # @yield whichever object was assigned to {#browser}
    #
    # @example If the page title is "Internal Server Error"
    #   config.server_error_detection { |browser|
    #     browser.has_css?('head title', :text => 'Internal Server Error')
    #   }
    def server_error_detection(&blk)
      if block_given?
        @server_error_detection = blk
      else
        @server_error_detection
      end
    end

    # The parsed version of the {#app_host}
    #
    # This is useful if, for example, you are testing a multi-host application
    # and need to change the hostname that will be accessed but want to keep the
    # originally-specified port
    #
    # @return [URI] A URI object created from the {#app_host} string
    def app_host_uri
      URI.parse(app_host)
    end
  end
end
