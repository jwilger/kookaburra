require 'kookaburra/json_api_driver'

describe Kookaburra::JsonApiDriver do
  let(:response) { '{"foo":"bar"}' }

  let(:api) {
    stub('APIDriver', :get => response, :post => response, :put => response,
         :delete => response, :headers= => nil)
  }

  let(:json) { Kookaburra::JsonApiDriver.new(:api_driver => api) }

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

  it 'delegates to a Kookaburra::APIDriver by default' do
    delegate = stub('Kookaburra::APIDriver', :foo => :bar).as_null_object
    Kookaburra::APIDriver.should_receive(:new).once.and_return(delegate)
    json = Kookaburra::JsonApiDriver.new
    json.foo.should == :bar
  end

  describe '#post' do
    it 'delegates to the api driver as a JSON request' do
      api.should_receive(:post) \
        .with('/foo', '{"foo":"bar"}') \
        .and_return('{"baz":"bam"}')
      json.post('/foo', 'foo' => 'bar')
    end

    it 'returns the JSON-decoded response body' do
      json.post('/foo', 'bar').should == {'foo' => 'bar'}
    end
  end

  describe '#put' do
    it 'delegates to the api driver as a JSON request' do
      api.should_receive(:put) \
        .with('/foo', '{"foo":"bar"}') \
        .and_return('{"baz":"bam"}')
      json.put('/foo', 'foo' => 'bar')
    end

    it 'returns the JSON-decoded response body' do
      json.put('/foo', 'bar').should == {'foo' => 'bar'}
    end
  end
end
