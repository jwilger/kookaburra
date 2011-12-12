class Class
  def __cattr_accessor_for_kookaburra(accessor, default_value = nil)
    if self.respond_to?(:class_attribute)
      class_attribute accessor
    else
      class_inheritable_accessor accessor
    end
    self.send("#{accessor}=", default_value) if default_value
  end
end
