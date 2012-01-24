module Kookaburra
  module Assertion
    # Custom exception class for assertion failures
    class Failure < Exception; end

    # Provides a mechanism for making assertions within your domain and window drivers
    # without creating a dependency on any specific testing framework.
    #
    # @param [Truthy] predicate The thing you are asserting should be `true` (or at least truthy).
    # @param [String] message Optional message to return if `predicate` is not `true` (or at least truthy).
    # @return [nil] if `predicate` does not evaluate to `false` or `nil`
    # @raise [Kookaburra::Assertion::Failure] if `predicate` evaluates to `false` or `nil`
    def assert(predicate, message = nil)
      return if predicate
      raise Failure, message
    rescue Failure => e
      raise Backtrace.clean(e)
    end

    # @private
    module Backtrace
      module_function
      
      def clean(exception)
        new_backtrace = exception.backtrace.dup
        new_backtrace.shift while new_backtrace.first.include?('lib/kookaburra/assertion.rb')
        exception.set_backtrace(new_backtrace)
        exception
      end
    end
  end
end
