require 'forwardable'

class Kookaburra
  # Your APIDriver subclass is used to define your testing DSL for setting up
  # test preconditions. Unlike {Kookaburra::APIClient}, which is meant to be a
  # simple mapping to your application's API, a method in the APIDriver may be
  # comprised of several distinct API calls as well as access to Kookaburra's
  # test data store via {#mental_model}.
  #
  # @abstract Subclass and implement your Given DSL.
  #
  # @example APIDriver subclass
  #   module MyApp
  #     module Kookaburra
  #       class APIDriver < ::Kookaburra::APIDriver
  #         def api
  #           @api ||= APIClient.new(configuration)
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
  class APIDriver
    extend Forwardable

    # It is unlikely that you would call #initialize yourself; your APIDriver
    # object is instantiated for you by {Kookaburra#given}.
    #
    # @param [Kookaburra::Configuration] configuration
    def initialize(configuration)
      @configuration = configuration
    end

    protected

    attr_reader :configuration

    # Access to the shared {Kookaburra::MentalModel} instance
    #
    # @attribute [rw] mental_model
    def_delegator :configuration, :mental_model

    # Used to access your APIClient in your own APIDriver implementation
    #
    # @abstract
    # @return [Kookaburra::APIClient]
    # @raise [Kookaburra::ConfigurationError] raised if you do not provide an
    #   implementation.
    def api
      raise ConfigurationError, "You must implement #api in your subclass."
    end
  end
end
