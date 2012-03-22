require 'kookaburra/dependency_accessor'

class Kookaburra
  # Your GivenDriver subclass is used to define your testing DSL for setting up
  # test preconditions. Unlike {Kookaburra::APIDriver}, which is meant to be a
  # simple mapping to your application's API, a method in the GivenDriver may be
  # comprised of several distinct API calls as well as access to Kookaburra's
  # test data store.
  #
  # @abstract Subclass and implement your Given DSL. You must also provide an
  #   implementation of #api that returns an instance of your APIDriver.
  #
  # @example GivenDriver subclass
  #   module MyApp
  #     module Kookaburra
  #       class GivenDriver < ::Kookaburra::GivenDriver
  #         def api
  #           @api ||= APIDriver.new(:app_host => initialization_options[:app_host])
  #         end
  #
  #         def a_widget(name, attributes = {})
  #           # Set up the data that will be passed to the API by merging any
  #           # passed attributes into the default data.
  #           data = {:name => 'Foo', :description => 'Bar baz'}.merge(attributes)
  #
  #           # Call the API method and get the resulting response as Ruby data.
  #           result = api.create_widget(data)
  #
  #           # Store the resulting widget data in the MentalModel object, so that
  #           # it can be referenced in other operations.
  #           mental_model.widgets[name] = result
  #         end
  #       end
  #     end
  #   end
  class GivenDriver
    extend DependencyAccessor

    # It is unlikely that you would call #initialize yourself; your GivenDriver
    # object is instantiated for you by {Kookaburra#given}.
    #
    # @option options [Kookaburra::MentalModel] :mental_model the MentalModel
    #   instance used by your tests
    # @option options [String] :app_host The root URL of your running
    #   application (e.g. "http://my_app.example.com:12345")
    def initialize(options = {})
      @initialization_options = options
      @mental_model = options[:mental_model]
    end

    protected

    # Used to access your APIDriver in your own GivenDriver implementation
    #
    # @abstract
    # @return [Kookaburra::APIDriver]
    # @raise [Kookaburra::ConfigurationError] raised if you do not provide an
    #   implementation.
    def api
      raise ConfigurationError, "You must implement #api in your subclass."
    end

    # The full set of options passed in to {#initialize}
    #
    # Access is provided so that you can use these when instantiating your
    # {APIDriver} in your {#api} implementation.
    attr_reader :initialization_options

    # A reference to the {Kookaburra::MentalModel} object that this GivenDriver
    # instance was created with.
    #
    # @attribute [r]
    # @return [Kookaburra::MentalModel]
    dependency_accessor :mental_model
  end
end
