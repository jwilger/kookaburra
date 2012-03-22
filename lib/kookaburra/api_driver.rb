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
      request(:post, path, options, data)
    end

    def put(path, data, options = {})
      request(:put, path, options, data)
    end

    def get(path, options = {})
      request(:get, path, options)
    end

    def delete(path, options = {})
      request(:delete, path, options)
    end

    private

    def request(type, path, options = {}, data = nil)
      # don't send a data argument if it's not passed in, because some methods
      # on target object may not have the proper arity (i.e. #get and #delete).
      args = [type, path, data, options].compact
      response = __getobj__.send(*args)

      check_response_status!(type, response, options)
      response.body
    end

    def check_response_status!(request_type, response, options)
      verb, default_status = verb_map[request_type]
      expected_status = options[:expected_response_status] || default_status
      unless expected_status == response.status
        raise UnexpectedResponse, "#{verb} to #{response.url} responded with " \
          + "#{response.status} status, not #{expected_status} as expected\n\n" \
          + response.body
      end
    end

    def verb_map 
      {
        :get => ['GET', 200],
        :post => ['POST', 201],
        :put => ['PUT', 200],
        :delete => ['DELETE', 200]
      }
    end
  end
end
