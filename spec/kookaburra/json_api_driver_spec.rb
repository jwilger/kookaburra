require 'kookaburra/json_api_driver'

describe Kookaburra::JsonApiDriver do
  describe '#initialize' do
    it 'instantiates a new APIDriver if no :api_driver option is passed' do
      Kookaburra::APIDriver.should_receive(:new).and_return(stub.as_null_object)
      Kookaburra::JsonApiDriver.new({})
    end

    it 'does not instantiate a new APIDriver if an :api_driver option is passed' do
      Kookaburra::APIDriver.should_receive(:new).never
      Kookaburra::JsonApiDriver.new(:api_driver => stub.as_null_object)
    end

    it 'sets appropriate headers for a JSON API request' do
      api = mock('APIDriver')
      api.should_receive(:headers=).with('Content-Type' => 'application/json',
                                         'Accept' => 'application/json')
      Kookaburra::JsonApiDriver.new(:api_driver => api)
    end
  end

  describe '#post' do
    it 'uses that api driver with which the object was initialized' do
      api = stub('APIDriver', :post => '{"foo":"bar"}', :headers= => nil)
      Kookaburra::APIDriver.should_receive(:new).once.and_return(api)
      json = Kookaburra::JsonApiDriver.new
      json.post('/foo', 'bar')
    end

    it 'delegates to the api driver as a JSON request' do
      api = mock('APIDriver', :headers= => nil)
      api.should_receive(:post) \
        .with('/foo', '{"foo":"bar"}') \
        .and_return('{"baz":"bam"}')
      json = Kookaburra::JsonApiDriver.new(:api_driver => api)
      json.post('/foo', 'foo' => 'bar')
    end

    it 'returns the JSON-decoded response body' do
      api = stub('APIDriver', :post => '{"foo":"bar"}', :headers= => nil)
      json = Kookaburra::JsonApiDriver.new(:api_driver => api)
      json.post('/foo', 'bar').should == {'foo' => 'bar'}
    end
  end
end
