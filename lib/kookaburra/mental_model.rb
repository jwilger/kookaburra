require 'delegate'
require 'kookaburra/exceptions'

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
      def initialize(name)
        @name = name
        data = Hash.new do |hash, key|
          raise UnknownKeyError, "Can't find mental_model.#{@name}[#{key.inspect}]. Did you forget to set it?"
        end
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
    end
  end
end
