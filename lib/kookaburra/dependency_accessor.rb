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

    def define_dependency_accessor(name)
      define_attr_reader(name)
      define_attr_writer(name)
    end

    def define_attr_reader(name)
      define_method(name) do
        class_name = self.class.name
        class_name.sub!(/^$/, 'an Anonymous Class!!!')
        instance_variable_get("@#{name}") or raise "No %s object was set on %s initialization." \
          % [name, class_name]
      end
    end

    def define_attr_writer(name)
      define_method("#{name}=") do |value|
        instance_variable_set("@#{name}", value)
      end
    end
  end
end
