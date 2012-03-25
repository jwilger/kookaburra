require 'kookaburra/json_api_driver'

describe Kookaburra::JsonApiDriver do
  let(:response) { '{"foo":"bar"}' }

  let(:api) {
    stub('APIDriver', :get => response, :post => response, :put => response,
         :delete => response, :headers => {})
  }

  let(:configuration) {
    stub('Configuration')
  }

  let(:json) { Kookaburra::JsonApiDriver.new(stub('Configuration'), api) }

  describe '#initialize' do
    it 'instantiates a new APIDriver if no :api_driver option is passed' do
      Kookaburra::APIDriver.should_receive(:new) \
        .with(configuration) \
        .and_return(api)
      Kookaburra::JsonApiDriver.new(configuration)
    end

    it 'does not instantiate a new APIDriver if an :api_driver option is passed' do
      Kookaburra::APIDriver.should_receive(:new).never
      Kookaburra::JsonApiDriver.new(configuration, api)
    end

    it 'sets appropriate headers for a JSON API request' do
      Kookaburra::JsonApiDriver.new(configuration, api)
      api.headers.should == {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    end
  end

  it 'delegates to a Kookaburra::APIDriver by default' do
    api.stub!(:foo => :bar)
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

  describe '#get' do
    it 'delegates to the api driver as a JSON request' do
      api.should_receive(:get) \
        .with('/foo') \
        .and_return('{"baz":"bam"}')
      json.get('/foo')
    end

    it 'returns the JSON-decoded response body' do
      json.get('/foo').should == {'foo' => 'bar'}
    end
  end

  describe '#delete' do
    it 'delegates to the api driver as a JSON request' do
      api.should_receive(:delete) \
        .with('/foo') \
        .and_return('{"baz":"bam"}')
      json.delete('/foo')
    end

    it 'returns the JSON-decoded response body' do
      json.delete('/foo').should == {'foo' => 'bar'}
    end
  end
end
