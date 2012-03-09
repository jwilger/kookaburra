class Kookaburra
  class UnknownKeyError < ArgumentError; end
  class ConfigurationError < StandardError; end
  class UnexpectedResponse < RuntimeError; end
  class AssertionFailed < RuntimeError; end
  class ComponentNotFound < RuntimeError; end
end
