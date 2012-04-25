class Kookaburra
  # @private
  class UnknownKeyError < ArgumentError; end
  # @private
  class ConfigurationError < StandardError; end
  # @private
  class UnexpectedResponse < RuntimeError
    attr_reader :status_code

    def initialize(status_code = nil)
      @status_code = status_code
    end
  end
  # @private
  class AssertionFailed < RuntimeError; end
  # @private
  class ComponentNotFound < RuntimeError; end
  # @private
  class NullBrowserError < ConfigurationError; end
end
