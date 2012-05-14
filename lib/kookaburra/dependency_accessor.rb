class Kookaburra
  # @private
  module DependencyAccessor
    # Creates a private attr_reader on the class that will raise an exception if
    # the attribute has a nil value when it is called. Useful for attributes
    # that can optionally be set in an object's constructor but it is not an
    # error for them to be missing unless something actually wants to use them.
    def dependency_accessor(*names)
      names.each { |name| define_dependency_accessor(name) }
    end

    private

    # TODO: refactor me to not look like shit, please
    def define_dependency_accessor(name)
      define_method(name) do
        instance_variable_get("@#{name}") or raise "No %s object was set on %s initialization." \
          % [name, [self.class.name, 'an Anonymous Class!!!'].reject{ |s| s == ""}.first]
      end

      define_method("#{name}=") do |value|
        instance_variable_set("@#{name}", value)
      end
    end
  end
end
