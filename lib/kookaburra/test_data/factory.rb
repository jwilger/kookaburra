# Factories for setting up attribute hashes
module Kookaburra
  class TestData
    class Factory
      attr_reader :test_data
      def initialize(test_data)
        @test_data = test_data
      end

      protected
      def hash_for_merging(overrides = {})
        overrides.dup.tap do |hash_to_merge|
          yield hash_to_merge if block_given?
        end
      end
    end
  end
end
