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
        @data = Hash.new do |hash, key|
          raise UnknownKeyError, "Can't find test_data.#{@name}[#{key.inspect}]. Did you forget to set it?"
        end
      end

      def ===(other)
        self.object_id == other.object_id
      end

      def [](*keys)
        if keys.size == 1
          @data[keys.first]
        else
          keys.map do |key|
            @data[key]
          end
        end
      end

      def method_missing(*args, &block)
        @data.send(*args, &block)
      end
    end
  end
end
