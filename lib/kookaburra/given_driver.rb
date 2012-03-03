require 'kookaburra/dependency_accessor'

class Kookaburra
  class GivenDriver
    extend DependencyAccessor

    dependency_accessor :test_data, :api

    def initialize(options = {})
      @test_data = options[:test_data]
      @api       = options[:api]
    end
  end
end
