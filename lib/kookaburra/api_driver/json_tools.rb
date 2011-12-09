module Kookaburra
  class APIDriver
    module JSONTools
      module ClassMethods
      end

      module InstanceMethods
        def post_as_json(short_description, path, data = {})
          header 'Content-Type', 'application/json'
          header 'Accept', 'application/json'
          post path, data.to_json
          raise_unless_created short_description
        end

        def put_as_json(short_description, path, data = {})
          header 'Content-Type', 'application/json'
          header 'Accept', 'application/json'
          put path, data.to_json
          raise_unless_created short_description
        end

        def hash_from_response_json
          HashWithIndifferentAccess.new( JSON.parse(last_response.body))
        end
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
  end
end
