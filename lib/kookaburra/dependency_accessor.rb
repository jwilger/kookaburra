require 'active_support/core_ext/string'

class Kookaburra
  module DependencyAccessor
    def dependency_accessor(*names)
      names.each do |n|
        define_method(n) do
          instance_variable_get("@#{n}") or raise "No %s object was set on %s initialization." \
            % [n, [self.class.name, 'an Anonymous Class!!!'].reject(&:blank?).first]
        end
        private n
      end
    end
  end
end
