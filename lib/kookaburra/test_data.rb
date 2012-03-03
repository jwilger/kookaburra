class Kookaburra
  class TestData
    UnknownKeyError = Class.new(StandardError)

    def initialize
      @data = {}
    end

    # TODO: def respond_to?
    def method_missing(name, *args)
      return super unless args.empty?
      @data[name] ||= Collection.new(name)
    end

    def default(name)
    end

    class Collection
      def initialize(name)
        @name = name
        @items = {}
      end

      def []=(key, value)
        @items[key] = value
      end

      def [](key)
        @items.fetch(key)
      rescue IndexError
        raise UnknownKeyError, "Can't find test_data.#{@name}[#{key.inspect}]. Did you forget to set it?"
      end
    end
  end
end
