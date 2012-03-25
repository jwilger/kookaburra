require 'kookaburra/exceptions'

class Kookaburra
  # Include this module wherever you need to be able to make a quick,
  # low-ceremony assertion.
  module Assertion
    protected

    # Provides a mechanism to make assertions about the state of your
    # UIComponent without relying on a specific testing framework. A good
    # reason to use this would be to provide a more informative error message
    # when a pre-condition is not met, rather than waiting on an operation
    # further down the line to fail.
    #
    # @param [boolean expression] test an expression that will be evaluated in a boolean context
    # @param [String] message the exception message that will be used if
    #   test is false
    #
    # @raise [Kookaburra::AssertionFailed] raised if test evaluates to false
    def assert(test, message = "You might want to provide a better message, eh?")
      test or raise AssertionFailed, message
    end
  end
end
