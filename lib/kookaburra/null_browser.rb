require 'basic_object'

class Kookaburra
  class NullBrowser < BasicObject
    def method_missing(*args)
      raise NullBrowserError, 
        "You did not provide a :browser to the Kookaburra configuration, but you tried to use one anyway."
    end
  end
end
