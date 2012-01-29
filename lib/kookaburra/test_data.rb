require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash'

module Kookaburra
  # This is the mechanism for sharing state between Cucumber steps.
  # If you're using instance variables, YOU'RE DOING IT WRONG.
  class TestData
    Defaults = HashWithIndifferentAccess.new

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

    class << self
      def provide_collection(name)
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

      def set_default(key, value)
        Kookaburra::TestData::Defaults[key] = value
      end

      def default(key)
        Defaults[key]
      end
    end

    def default(key)
      (@defaults ||= Defaults.deep_dup).fetch(key)
    end
  end
end
