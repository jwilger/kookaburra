require 'kookaburra/api_driver'

describe Kookaburra::APIDriver do
  def url_for(uri)
    URI.join('http://example.com', uri).to_s
  end

  let(:configuration) { stub('Configuration', :app_host => 'http://example.com') }

  let(:api) { Kookaburra::APIDriver.new(configuration, client) }

  let(:response) { stub('RestClient::Response', body: 'foo', code: 200) }

  let(:client) { stub('RestClient') }

  shared_examples_for 'any type of HTTP request' do |http_verb|
    before(:each) do
      client.stub!(http_verb => response)
    end

    it 'returns the response body' do
      api.send(http_verb, '/foo').should == 'foo'
    end

    it 'raises an UnexpectedResponse if the request is not successful' do
      response.stub!(code: 500)
      client.stub!(http_verb).and_raise(RestClient::Exception.new(response))
      lambda { api.send(http_verb, '/foo') } \
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
        # Some HTTP verb methods pass data, some don't, and their arity
        # is different
        client.should_receive(http_verb) do |path, data_or_headers, headers|
          headers ||= data_or_headers
          expect(headers).to eq('Header-Foo' => 'Baz', 'Header-Bar' => 'Bam')
          response
        end
        api.send(http_verb, '/foo')
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
        api.send(http_verb, '/foo').should == :some_decoded_data
      end
    end
  end

  shared_examples_for 'it encodes request data' do |http_verb|
    context "(#{http_verb})" do
      before(:each) do
        client.stub!(http_verb => response)
      end

      context 'when a custom encoder is specified' do
        let(:api) {
          klass = Class.new(Kookaburra::APIDriver) do
          encode_with { |data| :some_encoded_data }
          end
        klass.new(configuration, client)
        }

        it "encodes input to requests" do
          client.should_receive(http_verb) do |_, data, _|
            data.should == :some_encoded_data
            response
          end

          api.send(http_verb, '/foo')
        end
      end
    end
  end

  shared_examples_for 'it encodes data as a querystring' do |http_verb|
    context "(#{http_verb})" do
      it 'adds data as querystirng params' do
        client.should_receive(http_verb).with(url_for('/foo?bar=baz&yak=shaved'), {}) \
          .and_return(response)
        api.send(http_verb, '/foo', bar: 'baz', yak: 'shaved')
      end
    end
  end

  it_behaves_like 'any type of HTTP request', :get
  it_behaves_like 'any type of HTTP request', :post
  it_behaves_like 'any type of HTTP request', :put
  it_behaves_like 'any type of HTTP request', :delete

  it_behaves_like 'it encodes data as a querystring', :get
  it_behaves_like 'it encodes data as a querystring', :delete

  it_behaves_like 'it encodes request data', :post
  it_behaves_like 'it encodes request data', :put
end
