require 'kookaburra/api_driver'

describe Kookaburra::APIDriver do
  describe '#initialize' do
    it 'instantiates a new http client if no :http_client option is passed' do
      Patron::Session.should_receive(:new).and_return(stub.as_null_object)
      Kookaburra::APIDriver.new({})
    end

    it 'does not instantiate a new http client if an :http_client option is passed' do
      Patron::Session.should_receive(:new).never
      Kookaburra::APIDriver.new(:http_client => stub.as_null_object)
    end
  end

  describe '#headers=' do
    it 'sets each header on the client session' do
      headers = mock('Hash')
      headers.should_receive(:[]=).with('Foo', 'bar')
      headers.should_receive(:[]=).with('Baz', 'bam')
      client = stub('Patron::Session', :headers => headers)
      api = Kookaburra::APIDriver.new(:http_client => client)
      api.headers = {'Foo' => 'bar', 'Baz' => 'bam'}
    end
  end

  describe '#post' do
    it 'delegates posting to the http client' do
      client = mock('Patron::Session')
      client.should_receive(:post).with('/foo', 'bar', {}) \
        .and_return(stub(:status => 201, :body => ''))
      api = Kookaburra::APIDriver.new(:http_client => client)
      api.post('/foo', 'bar')
    end

    it 'returns the response body of the post' do
      response = stub('Patron::Response', :body => 'foo', :status => 201)
      client = stub('Patron::Session', :post => response)
      api = Kookaburra::APIDriver.new(:http_client => client)
      api.post('/foo', 'bar').should == 'foo'
    end

    it 'does not raise an UnexpectedResponse if the response status matches the specified expectation' do
      response = stub('Patron::Response', :status => 666, :body => '')
      client = stub('Patron::Session', :post => response)
      api = Kookaburra::APIDriver.new(:http_client => client)
      lambda { api.post('/foo', 'bar', :expected_response_status => 666) } \
        .should_not raise_error
    end

    it 'raises an UnexpectedResponse if the response status is not the specified status' do
      response = stub('Patron::Response', :status => 555)
      client = stub('Patron::Session', :post => response)
      api = Kookaburra::APIDriver.new(:http_client => client)
      lambda { api.post('/foo', 'bar', :expected_response_status => 666) } \
        .should raise_error(Kookaburra::UnexpectedResponse,
                            "POST to /foo responded with 555 status, not 666 as expected")
    end

    it 'defaults the expected response status to 201' do
      response = stub('Patron::Response', :status => 201, :body => '')
      client = stub('Patron::Session', :post => response)
      api = Kookaburra::APIDriver.new(:http_client => client)
      lambda { api.post('/foo', 'bar') } \
        .should_not raise_error
    end
  end
end
