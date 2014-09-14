class Kookaburra
  # Raised when accessing unknown mental model data
  # @private
  class UnknownKeyError < ArgumentError; end

  # Raised when there is a problem with the Kookaburra runtime configuration
  # @private
  class ConfigurationError < StandardError; end

  # Raised when an API or UI request results in an enexpected HTTP response
  # @private
  class UnexpectedResponse < RuntimeError; end

  # Raised when an assertion fails inside the drivers.
  # @private
  class AssertionFailed < RuntimeError; end

  # Raised when calling `api` or `ui` test helpers and named applications are
  # configured
  # @private
  class AmbiguousDriverError < StandardError; end
end
