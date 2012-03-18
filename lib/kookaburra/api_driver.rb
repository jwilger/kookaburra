class Kookaburra
  # This class currently exists only so that, in documentation, we can refer to
  # the generic APIDriver rather than the specific {Kookaburra::JsonApiDriver},
  # which is currently the only implementation. Once another APIDriver
  # implementation is added to Kookaburra, anything it has in common with
  # {Kookaburra::JsonApiDriver} should be factored up into this class.
  #
  # @abstract Subclass and provide an API client implementation
  class APIDriver
    # Returns a new APIDriver.
    #
    # @param args Not actually used, but takes any arguments
    def initialize(*args)
    end
  end
end
