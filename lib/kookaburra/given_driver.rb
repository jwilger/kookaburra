require 'kookaburra/dependency_accessor'

class Kookaburra
  class GivenDriver
    def initialize(options = {})
      @test_data = options[:test_data]
      @api       = options[:api]
    end

    private

    extend DependencyAccessor
    dependency_accessor :test_data, :api
  end
end
