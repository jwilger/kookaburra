require 'active_support/core_ext/string'

class Kookaburra
  module DependencyAccessor
    def dependency_accessor(*names)
      names.each { |name| define_dependency_accessor(name) }
    end

    private

    def define_dependency_accessor(name)
      define_method(name) do
        instance_variable_get("@#{name}") or raise "No %s object was set on %s initialization." \
          % [name, [self.class.name, 'an Anonymous Class!!!'].reject(&:blank?).first]
      end
      private name
    end
  end
end
