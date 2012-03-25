require 'basic_object'
require 'kookaburra/exceptions'

class Kookaburra
  # If you don't specify a browser in your {Kookaburra#configuration} but you
  # try to access one in your {Kookaburra::UIDriver}, you'll get this instead.
  # It gives a slightly better error message than complaining about calling
  # stuff on `nil`.
  class NullBrowser < BasicObject
    def method_missing(*args)
      raise NullBrowserError, 
        "You did not provide a :browser to the Kookaburra configuration, but you tried to use one anyway."
    end
  end
end
