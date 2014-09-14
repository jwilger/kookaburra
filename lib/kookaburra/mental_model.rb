require 'delegate'
require 'kookaburra/exceptions'

class Kookaburra
  # Each instance of {Kookaburra} has its own instance of MentalModel. This object
  # is used to maintain a shared understanding of the application state between
  # your {APIDriver} and your {UIDriver}. You can access the various test data
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
    def respond_to?(_)
      true
    end

    # A MentalModel::Collection behaves much like a {Hash} object, with the
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
      attr_reader :name

      # @param [String] name The name of the collection. Used to provide
      #   helpful error messages when unknown keys are accessed.
      # @param [Hash] init_data Preloads specific data into the collection
      def initialize(name, init_data = {})
        self.name = name
        data = Hash.new do |hash, key|
          raise UnknownKeyError, "Can't find mental_model.#{@name}[#{key.inspect}]. Did you forget to set it?"
        end
        data.merge!(init_data)
        super(data)
      end

      # Unlike a Hash, this object is only identical to another if the actual
      # {#object_id} attributes match.
      #
      # @return [Boolean]
      def ===(other)
        self.object_id == other.object_id
      end

      # Returns a new hash that contains key/value pairs for the
      # specified keys with values copied from this collection.
      #
      # @note This is semantically the same as {Hash#slice} as provided
      #   by {ActiveSupport::CoreExt::Hash}
      # @param [Object] keys The list of keys that should be copied from
      #   the collection
      # @return [Hash] The resulting keys/values from the collection
      def slice(*keys)
        data = keys.inject({}) { |memo, key|
          memo[key] = self[key]
          memo
        }
      end

      # Returns a new hash that contains every key/value from this
      # collection *except* for the specified keys
      #
      # @note This is semantically the same as {Hash#except} as provided
      #   by {ActiveSupport::CoreExt::Hash}
      # @param [Object] keys The list of keys that should *not* be
      #   copied from the collection
      # @return [Hash] The resulting keys/values from the collection
      def except(*keys)
        slice(*(self.keys - keys))
      end

      # Deletes a key/value pair from the collection, and persists the deleted pair
      # in a subcollection.
      #
      # Deleting a key/value pair from a collection on the MentalModel works just
      # like {Hash#delete} but with a side effect - deleted members are added to
      # a subcollection, accessible at {#deleted}.
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
      # Key/value pairs {#delete}d from a collection on the MentalModel will be added
      # to this subcollection.
      #
      # @return [Kookaburra::MentalModel::Collection] the deleted items subcollection
      def deleted
        @deleted ||= self.class.new("#{name}.deleted")
      end

      # Deletes key/value pairs from the collection for which the given block evaluates
      # to true, and persists all deleted pairs in a subcollection.
      #
      # Works just like {Hash#delete_if} but with a side effect - deleted members are
      # added to a subcollection, accessible at {#deleted}.
      #
      # @return [Hash] the key/value pairs still remaining after the deletion
      def delete_if(&block)
        move = ->(key, value) { deleted[key] = value; true }
        super { |key, value| block.call(key, value) && move.call(key, value) }
      end

      def dup
        new_data = {}.merge(self)
        new_data = Marshal.load(Marshal.dump(new_data))
        self.class.new(@name, new_data).tap do |mm|
          mm.deleted = deleted.dup unless deleted.empty?
        end
      end

      protected

      attr_writer :deleted

      private

      attr_writer :name
    end
  end
end
