require 'kookaburra/rack_driver'

describe Kookaburra::RackDriver do
  it 'has Rack::Test::Methods' do
    Kookaburra::RackDriver.should include(Rack::Test::Methods)
  end

  describe '#post' do
    it 'returns the response body' do
      app = stub('Rack App', :call => [201, {}, 'response body'])
      driver = Kookaburra::RackDriver.new(app)
      driver.post('/foo', 'req body').should == 'response body'
    end

    it 'sets the specified headers on the request' do
      app = mock('Rack App')
      driver = Kookaburra::RackDriver.new(app)
      app.should_receive(:call) do |env|
        env['HTTP_HEADER_A'].should == 'foo'
        env['HTTP_HEADER_B'].should == 'bar'
        [201, {}, 'foo']
      end
      driver.post('/foo', 'req body', 'header-a' => 'foo', 'header-b' => 'bar')
    end

    it 'raises a Kookabura::UnexpectedResponse if response status is not 201' do
      app_response = [200, {'Content-Type' => 'application/json'}, 'Here is the response body']
      app = stub('Rack App', :call => app_response)
      driver = Kookaburra::RackDriver.new(app)
      lambda { driver.send(:post, '/foo', {:bar => :baz}) } \
        .should raise_error(Kookaburra::UnexpectedResponse,
                            "post to /foo unexpectedly responded with an HTTP status of 200:\n" \
                            + 'Here is the response body')
    end
  end
end
