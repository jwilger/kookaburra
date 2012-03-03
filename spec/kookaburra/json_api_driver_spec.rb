require 'kookaburra/json_api_driver'

describe Kookaburra::JsonApiDriver do
  describe 'private methods (for use by subclasses)' do
    describe '#post' do
      it 'posts data as JSON to the specified path within the application' do
        app_driver = mock('RackDriver')
        app_driver.should_receive(:post) \
          .with('/foo', '{"bar":"baz"}',
                'Content-Type' => 'application/json',
                'Accept' => 'application/json') \
          .and_return('{"foo":"bar"}')
        driver = Kookaburra::JsonApiDriver.new(app_driver)
        driver.send(:post, '/foo', {:bar => :baz})
      end

      it 'returns the response body parsed from JSON' do
        app_driver = stub('RackDriver', :post => '{"ham":"spam"}')
        driver = Kookaburra::JsonApiDriver.new(app_driver)
        driver.send(:post, '/foo', {:bar => :baz}) \
          .should == {'ham' => 'spam'}
      end
    end
  end
end
