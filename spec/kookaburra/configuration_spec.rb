require 'kookaburra/configuration'
require 'support/shared_examples/it_has_a_dependency_accessor'

describe Kookaburra::Configuration do
  it_behaves_like :it_has_a_dependency_accessor, :given_driver_class
  it_behaves_like :it_has_a_dependency_accessor, :ui_driver_class
  it_behaves_like :it_has_a_dependency_accessor, :browser
  it_behaves_like :it_has_a_dependency_accessor, :app_host
  it_behaves_like :it_has_a_dependency_accessor, :mental_model
  it_behaves_like :it_has_a_dependency_accessor, :logger

  describe '#server_error_detection' do
    it 'returns the block that it was last given' do
      block = lambda { 'foo' }
      subject.server_error_detection(&block)
      subject.server_error_detection.should == block
    end
  end

  describe '#app_host_uri' do
    it 'returns a URI version of the #app_host attribute via URI.parse' do
      URI.should_receive(:parse) \
        .with('http://example.com') \
        .and_return(:a_parsed_uri)
      subject.app_host = 'http://example.com'
      subject.app_host_uri.should == :a_parsed_uri
    end

    it 'changes if #app_host changes' do
      URI.stub!(:parse) do |url|
        url.to_sym
      end
      subject.app_host = 'http://example.com'
      subject.app_host_uri.should == 'http://example.com'.to_sym
      subject.app_host = 'http://foo.example.com'
      subject.app_host_uri.should == 'http://foo.example.com'.to_sym
    end
  end
end
