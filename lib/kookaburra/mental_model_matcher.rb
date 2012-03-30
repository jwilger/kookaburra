require 'kookaburra/mental_model'

class Kookaburra
  class MentalModel
    # This is a custom matcher that matches the RSpec matcher API.
    # (The test_helpers.rb file provides a match function
    # for RSpec and a custom assertion for Test::Unit.)
    class Matcher
      def initialize(mental_model, collection_key)
        @collection_key = collection_key

        mental_model.send(collection_key).tap do |collection|
          @expected   = collection
          @unexpected = collection.deleted
        end
      end

      def expecting_nothing
        only
      end

      def only(*collection_keys)
        keepers = @expected.slice(*collection_keys)
        tossers = @expected.except(*collection_keys)

        @expected = keepers
        @unexpected.merge! tossers

        self
      end

      def matches?(actual)
        @actual = actual
        expected_items_not_found.empty? && unexpected_items_found.empty?
      end

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

      def failure_message_for_should_not
        "expected #{@collection_key} not to match the user's mental model"
      end

      def description
        "match the user's mental model of #{@collection_key}"
      end

    protected

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
    end
  end
end
