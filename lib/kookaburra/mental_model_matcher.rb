require 'kookaburra/mental_model'

class Kookaburra
  class MentalModel
    # This is a custom matcher that matches the RSpec matcher API.
    #
    # @see Kookaburra::TestHelpers#match_mental_model_of
    # @see Kookaburra::TestHelpers#assert_mental_model_of
    class Matcher
      def initialize(mental_model, collection_key)
        @collection_key = collection_key

        mental_model.send(collection_key).tap do |collection|
          @expected   = collection.dup
          @unexpected = collection.deleted.dup
        end
      end

      # Specifies that result should be limited to the given keys from the
      # mental model.
      #
      # Useful if you are looking at a filtered result. That is, your mental
      # model contains elements { A, B, C }, but you only expect to see element
      # A.
      #
      # @example
      #   matcher.only?(:foo, :bar, :baz)
      # @example With an array of keys
      #   keys = [:foo, :bar, :baz]
      #   matcher.only?(*keys)
      #
      # @param collection_keys The keys used in your mental model to reference
      #   the data - if you have an array, splat it.
      # @return [self]
      def only(*collection_keys)
        keepers = @expected.slice(*collection_keys)
        tossers = @expected.except(*collection_keys)

        @expected = keepers
        @unexpected.merge! tossers

        self
      end

      # Specifies that members of the expected collection should be mapped by
      # the given block before attempting to match.
      #
      # Useful if the result represents a modified version of what's on the
      # mental model.
      #
      # @yield [val] map function, run once for each member of the collection
      # @return [self]
      def mapped_by(&block)
        validate_block_arguments 'mapped_by', &block
        @expected = Hash[@expected.map { |key, val| [key, block.call(val)] }]
        @unexpected = Hash[@unexpected.map { |key, val| [key, block.call(val)] }]
        self
      end

      # Specifies that result should be filtered by a given block.
      #
      # Useful if you are looking at a filtered result based on given criteria.
      # That is, you only expect to see elements for which a given block
      # returns true.
      #
      # @yield [val] function used to select specific results from collection
      # @return [self]
      def where(&block)
        validate_block_arguments 'where', &block
        valid_keys = @expected.select { |key, val| block.call(val) }.map { |key, val| key }
        only *valid_keys
      end

      # Reads better than {#only} with no args
      #
      # @return [self]
      def expecting_nothing
        only
      end

      # The result contains everything that was expected to be found and nothing
      # that was unexpected.
      #
      # (Part of the RSpec protocol for custom matchers.)
      #
      # @param [Array] actual This is the data observed that you are attempting
      #   to match against the mental model.
      # @return Boolean
      def matches?(actual)
        @actual = actual
        expected_items_not_found.empty? && unexpected_items_found.empty?
      end

      # Message to be printed when observed reality does not conform to
      # mental model.
      #
      # (Part of the RSpec protocol for custom matchers.)
      #
      # @return String
      def failure_message_for_should
        message = "expected #{@collection_key} to match the user's mental model, but:\n"
        if expected_items_not_found.present?
          message += "expected to be present:         #{pp_array(expected_items)}\n"
          message += "the missing elements were:      #{pp_array(expected_items_not_found)}\n"
        end
        if unexpected_items_found.present?
          message += "expected to not be present:     #{pp_array(unexpected_items)}\n"
          message += "the unexpected extra elements:  #{pp_array(unexpected_items_found)}\n"
        end
        message
      end

      # Message to be printed when observed reality does conform to mental
      # model, but you did not expect it to.  (To be honest, we can't think of
      # why you would want this, but it is included for the sake of RSpec
      # compatibility.)
      #
      # (Part of the RSpec protocol for custom matchers.)
      #
      # @return String
      def failure_message_for_should_not
        "expected #{@collection_key} not to match the user's mental model"
      end

      # (Part of the RSpec protocol for custom matchers.)
      #
      # @return String
      def description
        "match the user's mental model of #{@collection_key}"
      end

      private

      def expected_items;   @expected.values;   end
      def unexpected_items; @unexpected.values; end

      def expected_items_not_found
        difference_between_arrays(expected_items, @actual)
      end

      def unexpected_items_found
        unexpected_items_not_found = difference_between_arrays(unexpected_items, @actual)
        difference_between_arrays(unexpected_items, unexpected_items_not_found)
      end

      # (Swiped from RSpec's array matcher)
      # Returns the difference of arrays, accounting for duplicates.
      # e.g., difference_between_arrays([1, 2, 3, 3], [1, 2, 3]) # => [3]
      def difference_between_arrays(array_1, array_2)
        difference = array_1.dup
        array_2.each do |element|
          if index = difference.index(element)
            difference.delete_at(index)
          end
        end
        difference
      end

      def pp_array(array)
        array = array.sort if array.all? { |e| e.respond_to?(:<=>) }
        array.inspect
      end

      def validate_block_arguments(method, &block)
        raise "Must supply a block to ##{method}" unless block_given?
        raise "Block supplied to ##{method} must take one argument (the value)" unless block.arity == 1
      end
    end
  end
end
