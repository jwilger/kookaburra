require 'delegate'

class Kookaburra
  class Configuration
    # Used to manage configuration for a named application
    #
    # `Configuration::Proxy` objects delegate to their basis object to retrieve
    # default values. This allows a base configuration to be specified and
    # inherited by each application configuration.
    #
    # @see Kookaburra::Configuration#application
    # @private
    class Proxy < DelegateClass(Configuration)
      attr_reader :name

      # Builds a new Proxy
      #
      # @param [String] name An (arbitrary) identifier for this configuration
      # @param [Kookaburra::Configuration] The object that will be used as the source for default values
      def initialize(name:, basis:)
        self.name = name
        self.basis = basis
        __setobj__(basis)
      end

      private

      attr_writer :name
      attr_accessor :basis

      def method_missing(method_name, *args, &block)
        define_proxy_override(method_name, args.first) \
          || super
      end

      def define_proxy_override(writer_name, value)
        return false unless valid_attr_writer?(writer_name)
        reader_name = reader_name_for writer_name
        (class << self; self; end).class_eval do
          define_method(reader_name) { value }
        end
        return true
      end

      def valid_attr_writer?(writer_name)
        basis.respond_to?(writer_name) \
          && /=$/ =~ writer_name.to_s
      end

      def reader_name_for(writer_name)
        writer_name.to_s.sub(/=$/, '')
      end
    end
  end
end
