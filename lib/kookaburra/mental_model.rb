require 'delegate'
require 'kookaburra/exceptions'
require 'active_support/core_ext/hash'

class Kookaburra
  # Each instance of {Kookaburra} has its own instance of MentalModel. This object
  # is used to maintain a shared understanding of the application state between
  # your {GivenDriver} and your {UIDriver}. You can access the various test data
  # collections in your test implementations via {Kookaburra#get_data}.
  #
  # The mental model is not intended to represent a copy of all of the data
  # within your application. Rather it is meant to represent the mental image of
  # the data that a user of your application might have while working with your
  # system. Certainly you *can* store whatever you want in it, but thinking
  # about it in these terms can help you design better, more robust tests.
  class MentalModel
    def initialize
      @data = {}
    end

    # MentalModel instances will respond to any message that has an arity of 0 by
    # returning either a new or existing {MentalModel::Collection} having the name
    # of the method.
    def method_missing(name, *args)
      return super unless args.empty?
      @data[name] ||= Collection.new(name)
    end

    # MentalModel instances respond to everything.
    #
    # @see #method_missing
    def respond_to?
      true
    end

    # A MentalModel::Collection behaves much like a `Hash` object, with the
    # exception that it will raise an {UnknownKeyError} rather than return nil
    # if you attempt to access a key that has not been set. The exception
    # attempts to provide a more helpful error message.
    #
    # @example
    #   widgets = Kookaburra::MentalModel::Collection.new('widgets')
    #
    #   widgets[:foo] = :a_foo
    #   
    #   widgets[:foo]
    #   #=> :a_foo
    #
    #   # Raises an UnknownKeyError
    #   mental_model.widgets[:bar]
    class Collection < SimpleDelegator
      # @param [String] name The name of the collection. Used to provide
      #   helpful error messages when unknown keys are accessed.
      # @param [Hash] init_data Preloads specific data into the collection
      def initialize(name, init_data = nil)
        @name = name
        data = Hash.new do |hash, key|
          raise UnknownKeyError, "Can't find mental_model.#{@name}[#{key.inspect}]. Did you forget to set it?"
        end
        data.merge!(init_data) unless init_data.nil?
        super(data)
      end

      # Unlike a Hash, this object is only identical to another if the actual
      # `#object_id` attributes match.
      #
      # @return [Boolean]
      def ===(other)
        self.object_id == other.object_id
      end

      # Deletes a key/value pair from the collection, and persists the deleted pair
      # in a subcollection.
      #
      # Deleting a key/value pair from a collection on the MentalModel works just
      # like `Hash#delete` but with a side effect - deleted members are added to
      # a subcollection, accessible at `#deleted`.
      #
      # @param key the key to delete from the collection
      #
      # @return the value of the deleted key/value pair
      #
      # @raise [Kookaburra::UnknownKeyError] if the specified key has not been set
      def delete(key, &block)
        self[key] # simple fetch to possibly trigger UnknownKeyError
        deleted[key] = super
      end

      # Finds or initializes, and returns, the subcollection of deleted items
      #
      # Key/value pairs `#delete`d from a collection on the MentalModel will be added
      # to this subcollection.
      #
      # @return [Kookaburra::MentalModel::Collection] the deleted items subcollection
      def deleted
        @deleted ||= self.class.new("deleted")
      end

      # Deletes key/value pairs from the collection for which the given block evaluates
      # to true, and persists all deleted pairs in a subcollection.
      #
      # Works just like `Hash#delete_if` but with a side effect - deleted members are
      # added to a subcollection, accessible at `#deleted`.
      #
      # @return [Hash] the key/value pairs still remaining after the deletion
      def delete_if(&block)
        move = lambda { |k,v| deleted[k] = v; true }
        super { |k,v| block.call(k,v) && move.call(k,v) }
      end

      def dup
        new_data = {}.merge(self)
        new_data = Marshal.load(Marshal.dump(new_data))
        self.class.new(@name, new_data)
      end
    end

    # This is a custom matcher that matches the RSpec matcher API.
    # (The test_helpers.rb file provides a match function
    # for RSpec and a custom assertion for Test::Unit.)
    class Matcher
      attr_reader :expected_items, :unexpected_items, :collection_key

      def initialize(mental_model, collection_key)
        @collection_key = collection_key

        mental_model.send(collection_key).tap do |collection|
          @expected_items   = collection.values
          @unexpected_items = collection.deleted.values
        end
      end

      # TODO: uncomment these as specs demand them
      # def expecting_nothing
      #   only
      # end
      #
      # def only(*collection_keys)
      #   collection_keys.map!(&:to_s)
      #   keepers = @mental_model[:expected].slice(*collection_keys)
      #   tossers = @mental_model[:expected].except(*collection_keys)
      #
      #   @mental_model[:expected] = keepers
      #   @mental_model[:unexpected].merge! tossers
      #   self
      # end

      def matches?(actual)
        @actual = actual
        clear_memoization!
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

      def clear_memoization!
        @expected_items_not_found = @unexpected_items_found = nil
      end

      def expected_items_not_found
        @expected_items_not_found ||= begin
          difference_between_arrays(expected_items, @actual)
        end
      end

      def unexpected_items_found
        @unexpected_items_found ||= begin
          unexpected_items_not_found = difference_between_arrays(unexpected_items, @actual)
          difference_between_arrays(unexpected_items, unexpected_items_not_found)
        end
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
