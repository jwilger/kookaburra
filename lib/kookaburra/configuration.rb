require 'ostruct'
require 'delegate'
require 'kookaburra/dependency_accessor'

class Kookaburra
  class Configuration
    extend DependencyAccessor
    dependency_accessor :given_driver_class
    dependency_accessor :ui_driver_class
    dependency_accessor :browser
    dependency_accessor :app_host
    dependency_accessor :mental_model

    def server_error_detection(&blk)
      if block_given?
        @server_error_detection = blk
      else
        @server_error_detection
      end
    end
  end
end
