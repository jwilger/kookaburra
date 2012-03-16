require 'kookaburra/json_api_driver'

describe Kookaburra::JsonApiDriver do
  describe 'protected methods (for use by subclasses)' do
    ['post', 'put', 'get'].each do |method|
      describe "##{method}" do
        it "sends a #{method} request with JSON data to the specified path within the application" do
          app_driver = mock('RackDriver')
          app_driver.should_receive(method.to_sym) \
            .with('/foo', '{"bar":"baz"}',
                  'Content-Type' => 'application/json',
                  'Accept' => 'application/json') \
            .and_return('{"foo":"bar"}')
          driver = Kookaburra::JsonApiDriver.new(app_driver)
          driver.send(method.to_sym, '/foo', {:bar => :baz})
        end

        it 'returns the response body parsed from JSON' do
          app_driver = stub('RackDriver', method.to_sym => '{"ham":"spam"}')
          driver = Kookaburra::JsonApiDriver.new(app_driver)
          driver.send(method.to_sym, '/foo', {:bar => :baz}) \
            .should == {:ham => 'spam'}
        end
      end
    end

    describe '#authorize' do
      it 'sets the authorization credentials on the app driver' do
        app_driver = mock('RackDriver')
        app_driver.should_receive(:authorize).with('a user', 'a password')
        driver = Kookaburra::JsonApiDriver.new(app_driver)
        driver.send(:authorize, 'a user', 'a password')
      end
    end
  end
end
