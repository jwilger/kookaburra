require 'kookaburra/api_driver'

describe Kookaburra::APIDriver do
  let(:configuration) { stub('Configuration', :app_host => 'http://example.com') }

  let(:api) { Kookaburra::APIDriver.new(configuration, client) }

  let(:response) {
    stub('Patron::Response', :body => 'foo', :status => 200, :url => '/foo')
  }

  let(:client) {
         mock('Patron::Session', :post => response, :get => response,
         :put => response, :delete => response, :base_url= => nil)
  }

  describe '#initialize' do
    it 'instantiates a new http client if no :http_client option is passed' do
      Patron::Session.should_receive(:new).and_return(stub.as_null_object)
      Kookaburra::APIDriver.new(configuration)
    end

    it 'does not instantiate a new http client if an :http_client option is passed' do
      Patron::Session.should_receive(:new).never
      Kookaburra::APIDriver.new(configuration, client)
    end
  end

  shared_examples_for 'an input data encoder' do |request_method|
    let(:api) {
      klass = Class.new(Kookaburra::APIDriver) do
        encode_with { |data| :some_encoded_data }
      end
      klass.new(configuration, client)
    }

    it "encodes input to #{request_method} requests" do
      client.should_receive(request_method) do |_, data, _|
        data.should == :some_encoded_data
        response
      end

      api.send(request_method, '/foo', :ruby_data)
    end
  end

  shared_examples_for 'a response body decoder' do |request_method|
    let(:api) {
      klass = Class.new(Kookaburra::APIDriver) do
        decode_with { |data| :some_decoded_data }
      end
      klass.new(configuration, client)
    }

    it "decodes response bodies from #{request_method} requests" do
      api.send(request_method, '/foo', {}).should == :some_decoded_data
    end
  end

  describe '#post' do
    before(:each) do
      response.stub!(:status => 201)
    end

    it 'delegates to the http client' do
      client.should_receive(:post).with('/foo', 'bar', {}) \
        .and_return(response)
      api.post('/foo', 'bar')
    end

    it 'returns the response body' do
      api.post('/foo', 'bar').should == 'foo'
    end

    it_behaves_like 'an input data encoder', :post
    it_behaves_like 'a response body decoder', :post

    it 'does not raise an UnexpectedResponse if the response status matches the specified expectation' do
      response.stub!(:status => 666)
      lambda { api.post('/foo', 'bar', :expected_response_status => 666) } \
        .should_not raise_error
    end

    it 'raises an UnexpectedResponse if the response status is not the specified status' do
      lambda { api.post('/foo', 'bar', :expected_response_status => 666) } \
        .should raise_error(Kookaburra::UnexpectedResponse,
                            "POST to /foo responded with 201 status, not 666 as expected\n\nfoo")
    end

    it 'is OK by default with a response status of 201' do
      lambda { api.post('/foo', 'bar') } \
        .should_not raise_error(Kookaburra::UnexpectedResponse)
    end

    it 'is OK by default with a response status of 200' do
      response.stub!(:status => 200)
      lambda { api.post('/foo', 'bar') } \
        .should_not raise_error(Kookaburra::UnexpectedResponse)
    end

    it 'raises an ArgumentError with a useful message if no request path is specified' do
      lambda { api.post(nil, 'bar') } \
        .should raise_error(ArgumentError, "You must specify a request URL, but it was nil.")
    end
  end

  describe '#put' do
    it 'delegates to the http client' do
      client.should_receive(:put).with('/foo', 'bar', {}) \
        .and_return(response)
      api.put('/foo', 'bar')
    end

    it 'returns the response body' do
      api.put('/foo', 'bar').should == 'foo'
    end

    it_behaves_like 'an input data encoder', :put
    it_behaves_like 'a response body decoder', :put

    it 'does not raise an UnexpectedResponse if the response status matches the specified expectation' do
      response.stub!(:status => 666)
      lambda { api.put('/foo', 'bar', :expected_response_status => 666) } \
        .should_not raise_error
    end

    it 'raises an UnexpectedResponse if the response status is not the specified status' do
      lambda { api.put('/foo', 'bar', :expected_response_status => 666) } \
        .should raise_error(Kookaburra::UnexpectedResponse,
                            "PUT to /foo responded with 200 status, not 666 as expected\n\nfoo")
    end

    it 'raises an ArgumentError with a useful message if no request path is specified' do
      lambda { api.put(nil, 'bar') } \
        .should raise_error(ArgumentError, "You must specify a request URL, but it was nil.")
    end
  end

  describe '#get' do
    it 'delegates to the http client' do
      client.should_receive(:get).with('/foo', {}) \
        .and_return(response)
      api.get('/foo')
    end

    it 'returns the response body' do
      api.get('/foo').should == 'foo'
    end

    it_behaves_like 'a response body decoder', :get

    it 'does not raise an UnexpectedResponse if the response status matches the specified expectation' do
      response.stub!(:status => 666)
      lambda { api.get('/foo', :expected_response_status => 666) } \
        .should_not raise_error
    end

    it 'raises an UnexpectedResponse if the response status is not the specified status' do
      lambda { api.get('/foo', :expected_response_status => 666) } \
        .should raise_error(Kookaburra::UnexpectedResponse,
                            "GET to /foo responded with 200 status, not 666 as expected\n\nfoo")
    end

    it 'raises an ArgumentError with a useful message if no request path is specified' do
      lambda { api.get(nil) } \
        .should raise_error(ArgumentError, "You must specify a request URL, but it was nil.")
    end
  end

  describe '#delete' do
    it 'delegates to the http client' do
      client.should_receive(:delete).with('/foo', {}) \
        .and_return(response)
      api.delete('/foo')
    end

    it 'returns the response body' do
      api.delete('/foo').should == 'foo'
    end

    it_behaves_like 'a response body decoder', :delete

    it 'does not raise an UnexpectedResponse if the response status matches the specified expectation' do
      response.stub!(:status => 666)
      lambda { api.delete('/foo', :expected_response_status => 666) } \
        .should_not raise_error
    end

    it 'raises an UnexpectedResponse if the response status is not the specified status' do
      lambda { api.delete('/foo', :expected_response_status => 666) } \
        .should raise_error(Kookaburra::UnexpectedResponse,
                            "DELETE to /foo responded with 200 status, not 666 as expected\n\nfoo")
    end

    it 'raises an ArgumentError with a useful message if no request path is specified' do
      lambda { api.delete(nil) } \
        .should raise_error(ArgumentError, "You must specify a request URL, but it was nil.")
    end
  end
end
