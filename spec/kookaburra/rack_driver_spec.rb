require 'kookaburra/rack_driver'

describe Kookaburra::RackDriver do
  it 'has Rack::Test::Methods' do
    Kookaburra::RackDriver.should include(Rack::Test::Methods)
  end

  {
    'post' => {:success => 201, :unexpected => 200},
    'put'  => {:success => 200, :unexpected => 404},
    'get'  => {:success => 200, :unexpected => 404}
  }.each_pair do |method, codes|
    describe "##{method}" do
      it 'returns the response body' do
        app = stub('Rack App', :call => [codes[:success], {}, 'response body'])
        driver = Kookaburra::RackDriver.new(app)
        driver.send(method.to_sym, '/foo', 'req body').should == 'response body'
      end

      it 'sets the specified headers on the request' do
        app = mock('Rack App')
        driver = Kookaburra::RackDriver.new(app)
        app.should_receive(:call) do |env|
          env['HTTP_HEADER_A'].should == 'foo'
          env['HTTP_HEADER_B'].should == 'bar'
          [codes[:success], {}, 'foo']
        end
        driver.send(method.to_sym, '/foo', 'req body', 'header-a' => 'foo', 'header-b' => 'bar')
      end

      it "raises a Kookabura::UnexpectedResponse if response status is not #{codes[:success]}" do
        app_response = [codes[:unexpected], {'Content-Type' => 'application/json'}, 'Here is the response body']
        app = stub('Rack App', :call => app_response)
        driver = Kookaburra::RackDriver.new(app)
        lambda { driver.send(method, '/foo', {:bar => :baz}) } \
          .should raise_error(Kookaburra::UnexpectedResponse,
                              "#{method} to /foo unexpectedly responded with an HTTP status of #{codes[:unexpected]}:\n" \
                              + 'Here is the response body')
      end
    end
  end
end
