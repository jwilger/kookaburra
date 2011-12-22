# This is the mechanism for sharing state between Cucumber steps.
# If you're using instance variables, YOU'RE DOING IT WRONG.
module Kookaburra
  class TestData
    def initialize
      @data = Hash.new do |hash, key|
        hash[key] = Hash.new { |hash, key| hash[key] = HashWithIndifferentAccess.new }
      end
    end

    def __collection(collection_key)
      @data[collection_key]
    end
    def __fetch_data(collection_key, value_key)
      __collection(collection_key).fetch(value_key)
    rescue IndexError => e
      raise e.exception("Key #{value_key.inspect} not found in #{collection_key}")
    end
    def __get_data(collection_key, value_key)
      __collection(collection_key)[value_key]
    end
    def __set_data(collection_key, value_key, value_hash = {})
      __collection(collection_key)[value_key] = HashWithIndifferentAccess.new(value_hash)
    end

    def self.provide_collection(name)
      class_eval <<-RUBY
        def #{name}(key = :default)
          __get_data(:#{name}, key)
        end
        def fetch_#{name}(key = :default)
          __fetch_data(:#{name}, key)
        end
        def set_#{name}(key, value_hash = {})
          __set_data(:#{name}, key, value_hash)
        end
      RUBY
    end

    Defaults = HashWithIndifferentAccess.new
    def default(key)
      # NOTE: Marshal seems clunky, but gives us a deep copy.
      # This keeps mutations from being preserved between test runs.
      ( @default ||= Marshal::load(Marshal.dump(Defaults)) )[key]
    end

    def factory
      @factory ||= Kookaburra::TestData::Factory.new(self)
    end
  end
end
