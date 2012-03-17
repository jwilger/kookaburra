class Kookaburra
  # @private
  class UnknownKeyError < ArgumentError; end
  # @private
  class ConfigurationError < StandardError; end
  # @private
  class UnexpectedResponse < RuntimeError; end
  # @private
  class AssertionFailed < RuntimeError; end
  # @private
  class ComponentNotFound < RuntimeError; end
  # @private
  class NullBrowserError < ConfigurationError; end
end
