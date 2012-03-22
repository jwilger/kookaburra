require 'delegate'

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

      # Returns the values of multiple keys from the collection.
      #
      # Unlike the `Hash#slice` implementation provided by ActiveSupport, this
      # method returns an array of the values rather than a Hash.
      #
      # @param keys a list of keys to fetch from the collection.
      #
      # @return [Array] the values matching the specified index keys
      #
      # @raise [Kookaburra::UnknownKeyError] if any of the specified keys have
      #   not been set
      def slice(*keys)
        results = keys.map do |key|
          self[key]
        end
      end
    end
  end
end
