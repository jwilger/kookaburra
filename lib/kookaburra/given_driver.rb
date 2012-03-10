require 'kookaburra/dependency_accessor'

class Kookaburra
  # Your GivenDriver subclass is used to define your testing DSL for setting up
  # test preconditions. Unlike {Kookaburra::APIDriver}, which is meant to be a
  # simple mapping to your application's API, a method in the GivenDriver may be
  # comprised of several distinct API calls as well as access to Kookaburra's
  # test data store.
  #
  # @abstract Subclass and implement your Given DSL
  #
  # @example GivenDriver subclass
  #   module MyApp
  #     module Kookaburra
  #       class GivenDriver < ::Kookaburra::GivenDriver
  #         def a_widget(name, attributes = {})
  #           # Set up the data that will be passed to the API by merging any
  #           # passed attributes into the default data.
  #           data = {:name => 'Foo', :description => 'Bar baz'}.merge(attributes)
  #
  #           # Call the API method and get the resulting response as Ruby data.
  #           result = api.create_widget(data)
  #
  #           # Store the resulting widget data in the TestData object, so that
  #           # it can be referenced in other operations.
  #           test_data.widgets[name] = result
  #         end
  #       end
  #     end
  #   end
  class GivenDriver
    extend DependencyAccessor

    # It is unlikely that you would call #initialize yourself; your GivenDriver
    # object is instantiated for you by {Kookaburra#given}.
    #
    # @option options [Kookaburra::TestData] the test data store
    # @option options [Kookaburra::APIDriver] the APIDriver subclass to be used
    def initialize(options = {})
      @test_data = options[:test_data]
      @api       = options[:api]
    end

    protected

    # A reference to the {Kookaburra::TestData} object that this GivenDriver
    # instance was created with.
    #
    # @attribute [r]
    # @return [Kookaburra::TestData]
    dependency_accessor :test_data

    # A reference to the {Kookaburra::APIDriver} that this GivenDriver instance
    # was created with.
    #
    # @attribute [r]
    # @return [Kookaburra::APIDriver]
    dependency_accessor :api
  end
end
