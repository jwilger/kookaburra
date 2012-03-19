require 'kookaburra/exceptions'
require 'delegate'
require 'patron'

class Kookaburra
  class APIDriver < SimpleDelegator
    def initialize(options = {})
      http_client = options[:http_client] || Patron::Session.new
      super(http_client)
    end

    def headers=(new_headers)
      new_headers.each do |k,v|
        headers[k] = v
      end
    end

    def post(path, data, options = {})
      expected_status = options[:expected_response_status] || 201
      response = super
      if response.status == expected_status
        response.body
      else
        raise UnexpectedResponse, "POST to #{path} responded with #{response.status} status, not #{expected_status} as expected"
      end
    end
  end
end
