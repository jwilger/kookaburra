# Factories for setting up attribute hashes
class Kookaburra::TestData
  class Factory
    attr_reader :test_data
    def initialize(test_data)
      @test_data = test_data
    end
  end
end
