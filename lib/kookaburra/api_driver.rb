require 'kookaburra/exceptions'
require 'delegate'
require 'patron'

class Kookaburra
  class APIDriver < SimpleDelegator
    def initialize(options = {})
      http_client = options[:http_client] || Patron::Session.new
      http_client.base_url = options[:app_host] if options.has_key?(:app_host)
      super(http_client)
    end

    def headers=(new_headers)
      new_headers.each do |k,v|
        headers[k] = v
      end
    end

    def post(path, data, options = {})
      expected_status = options[:expected_response_status] || 201
      response = super(path, data)
      if response.status == expected_status
        response.body
      else
        raise UnexpectedResponse, "POST to #{path} responded with " \
          + "#{response.status} status, not #{expected_status} as expected\n\n" \
          + response.body
      end
    end

    def put(path, data, options = {})
      expected_status = options[:expected_response_status] || 200
      response = super(path, data)
      if response.status == expected_status
        response.body
      else
        raise UnexpectedResponse, "PUT to #{path} responded with " \
          + "#{response.status} status, not #{expected_status} as expected\n\n" \
          + response.body
      end
    end

    def get(path, options = {})
      expected_status = options[:expected_response_status] || 200
      response = super(path)
      if response.status == expected_status
        response.body
      else
        raise UnexpectedResponse, "GET to #{path} responded with " \
          + "#{response.status} status, not #{expected_status} as expected\n\n" \
          + response.body
      end
    end

    def delete(path, options = {})
      expected_status = options[:expected_response_status] || 200
      response = super(path)
      if response.status == expected_status
        response.body
      else
        raise UnexpectedResponse, "DELETE to #{path} responded with " \
          + "#{response.status} status, not #{expected_status} as expected\n\n" \
          + response.body
      end
    end
  end
end
