require 'kookaburra/api_driver'

describe Kookaburra::APIDriver do
  def url_for(uri)
    URI.join('http://example.com', uri).to_s
  end

  let(:configuration) { stub('Configuration', :app_host => 'http://example.com') }

  let(:api) { Kookaburra::APIDriver.new(configuration, client) }

  let(:response) { stub('RestClient::Response', body: 'foo', code: 200) }

  let(:client) { stub('RestClient') }

  it 'sends POST requests to the server and returns the response body' do
    client.should_receive(:post).with(url_for('/foo'), 'bar', {}) \
      .and_return(response)
    api.post('/foo', 'bar').should == 'foo'
  end

  it 'sends PUT requests to the server and returns the response body' do
    client.should_receive(:put).with(url_for('/foo'), 'bar', {}) \
      .and_return(response)
    api.put('/foo', 'bar').should == 'foo'
  end

  it 'sends GET requests to the server and returns the response body' do
    client.should_receive(:get).with(url_for('/foo'), {}) \
      .and_return(response)
    api.get('/foo').should == 'foo'
  end

  it 'sends DELETE requests to the server and returns the response body' do
    client.should_receive(:delete).with(url_for('/foo'), {}) \
      .and_return(response)
    api.delete('/foo').should == 'foo'
  end

  describe 'any type of HTTP request' do
    before(:each) do
      client.stub!(:http_verb => response)
    end

    it 'returns the response body' do
      api.request(:http_verb, '/foo', 'bar').should == 'foo'
    end

    it 'raises an UnexpectedResponse if the request is not successful' do
      response.stub!(code: 500)
      client.stub!(:http_verb).and_raise(RestClient::Exception.new(response))
      lambda { api.request(:http_verb, '/foo') } \
        .should raise_error(Kookaburra::UnexpectedResponse)
    end

    context 'when custom headers are specified' do
      let(:api) {
        klass = Class.new(Kookaburra::APIDriver) do
          header 'Header-Foo', 'Baz'
          header 'Header-Bar', 'Bam'
        end
        klass.new(configuration, client)
      }

      it "sets headers on requests" do
        client.should_receive(:http_verb).with(url_for('/foo'), {}, 'Header-Foo' => 'Baz', 'Header-Bar' => 'Bam')
        api.request(:http_verb, '/foo', {})
      end
    end

    context 'when a custom encoder is specified' do
      let(:api) {
        klass = Class.new(Kookaburra::APIDriver) do
          encode_with { |data| :some_encoded_data }
        end
        klass.new(configuration, client)
      }

      it "encodes input to requests" do
        client.should_receive(:http_verb) do |_, data, _|
          data.should == :some_encoded_data
          response
        end

        api.request(:http_verb, '/foo', :ruby_data)
      end
    end

    context 'when a custom decoder is specified' do
      let(:api) {
        klass = Class.new(Kookaburra::APIDriver) do
        decode_with { |data| :some_decoded_data }
        end
        klass.new(configuration, client)
      }

      it "decodes response bodies from requests" do
        api.request(:http_verb, '/foo').should == :some_decoded_data
      end
    end
  end
end
