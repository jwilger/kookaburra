module Kookaburra
  class APIDriver
    module Plumbing
      module ClassMethods
      end
      
      module InstanceMethods
        def initialize(opts)
          @app       = opts.fetch(:app)
          @test_data = opts.fetch(:test_data)
        end

        def raise_unless_status(expected_status, short_description)
          message = "%s failed (#{last_response.status})\n#{last_response.body}" % short_description
          raise message unless last_response.status == expected_status
        end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.send :include, Rack::Test::Methods
        receiver.send :attr_reader, :app, :test_data
        receiver.send :protected, :app, :test_data
      end
    end
  end
end
