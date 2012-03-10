require 'kookaburra/dependency_accessor'

class Kookaburra
  # Your GivenDriver subclass is used to define your testing DSL for setting up
  # test preconditions. Unlike {Kookaburra::APIDriver}, which is meant to be a
  # simple mapping to your application's API, a method in the GivenDriver may be
  # comprised of several distinct API calls as well as access to Kookaburra's
  # test data store.
  class GivenDriver
    extend DependencyAccessor

    # It is unlikely that you would call #initialize yourself; your GivenDriver
    # object is instantiated for you by your {Kookaburra} object.
    #
    # @option options [Kookaburra::TestData] the test data store
    # @option options [Kookaburra::APIDriver] the APIDriver subclass to be used
    def initialize(options = {})
      @test_data = options[:test_data]
      @api       = options[:api]
    end

    protected

    # @attribute [r]
    dependency_accessor :test_data

    # @attribute [r]
    dependency_accessor :api
  end
end
