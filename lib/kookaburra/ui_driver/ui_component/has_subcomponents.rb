module Kookaburra
  class UIDriver
    class UIComponent
      module HasSubcomponents
        # Nothing to see here, really -- this just gives us a way to logically group subsections in a file
        def subcomponent(name, &proc)
          class_eval &proc
        end
      end
    end
  end
end
