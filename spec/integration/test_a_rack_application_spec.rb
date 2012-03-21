require 'kookaburra'
require 'kookaburra/json_api_driver'
require 'capybara'

# These are required for the Rack app used for testing
require 'sinatra/base'
require 'active_support/json'
require 'active_support/hash_with_indifferent_access'

describe "testing a Rack application with Kookaburra" do
  describe "with an HTML interface" do
    describe "with a JSON API" do
      # This is the fixture Rack application against which the integration
      # test will run. It uses class variables to persist data, because
      # Sinatra will instantiate a new instance of TestRackApp for each
      # request.
      class JsonApiApp < Sinatra::Base
        enable :sessions
        disable :show_exceptions

        def parse_json_req_body
          request.body.rewind
          ActiveSupport::JSON.decode(request.body.read).symbolize_keys
        end

        post '/users' do
          user_data = parse_json_req_body
          @@users ||= {}
          @@users[user_data[:email]] = user_data
          status 201
          headers 'Content-Type' => 'application/json'
          body user_data.to_json
        end

        post '/session' do
          user = @@users[params[:email]]
          if user && user[:password] == params[:password]
            session[:logged_in] = true
            status 200
            body 'You are logged in!'
          else
            session[:logged_in] = false
            status 403
            body 'Log in failed!'
          end
        end

        get '/session/new' do
          body <<-EOF
            <html>
              <head>
                <title>Sign In</title>
              </head>
              <body>
                <div id="sign_in_screen">
                  <form action="/session" method="POST">
                    <label for="email">Email:</label>
                    <input id="email" name="email" type="text" />

                    <label for="password">Password:</label>
                    <input id="password" name="password" type="password" />

                    <input type="submit" value="Sign In" />
                  </form>
                </div>
              </body>
            </html>
          EOF
        end

        post '/widgets/:widget_id' do
          @@widgets.delete_if do |w|
            w[:id] == params['widget_id']
          end
          redirect to('/widgets')
        end

        get '/widgets/new' do
          body <<-EOF
            <html>
              <head>
                <title>New Widget</title>
              </head>
              <body>
                <div id="widget_form">
                  <form action="/widgets" method="POST">
                    <label for="name">Name:</label>
                    <input id="name" name="name" type="text" />

                    <input type="submit" value="Save" />
                  </form>
                </div>
              </body>
            </html>
          EOF
        end

        post '/widgets' do
          @@widgets ||= []
          widget_data = if request.media_type == 'application/json'
                          parse_json_req_body
                        else
                          params.symbolize_keys.slice(:name)
                        end
          widget_data[:id] = `uuidgen`.strip
          @@widgets << widget_data
          @@last_widget_created = widget_data
          if request.accept? 'text/html'
            redirect to('/widgets')
          elsif request.accept? 'application/json'
            status 201
            headers 'Content-Type' => 'application/json'
            body widget_data.to_json
          else
            redirect to('/widgets')
          end
        end

        get '/widgets' do
          raise "Not logged in!" unless session[:logged_in]
          @@widgets ||= []
          last_widget_created, @@last_widget_created = @@last_widget_created, nil
          content = ''
          content << <<-EOF
          <html>
            <head>
              <title>Widgets</title>
            </head>
            <body>
              <div id="widget_list">
          EOF
          if last_widget_created
            content << <<-EOF
                  <div class="last_widget created">
                    <span class="id">#{last_widget_created[:id]}</span>
                    <span class="name">#{last_widget_created[:name]}</span>
                  </div>
            EOF
          end
          content << <<-EOF
                <ul>
          EOF
          @@widgets.each do |w|
            content << <<-EOF
                  <li class="widget_summary">
                    <span class="id">#{w[:id]}</span>
                    <span class="name">#{w[:name]}</span>
                    <form id="delete_#{w[:id]}" action="/widgets/#{w[:id]}" method="POST">
                      <button type="submit" value="Delete" />
                    </form>
                  </li>
            EOF
          end
          content << <<-EOF
                </ul>
                <a href="/widgets/new">New Widget</a>
              </div>
            </body>
          </html>
          EOF
          body content
        end

        error do
          e = request.env['sinatra.error']
          body << <<-EOF
          <html>
            <head>
              <title>Internal Server Error</title>
            </head>
            <body>
              <pre>
          #{e.to_s}\n#{e.backtrace.join("\n")}
              </pre>
            </body>
          </html>
          EOF
        end
      end

      class MyAPIDriver < Kookaburra::JsonApiDriver
        def create_user(user_data)
          post '/users', user_data
        end

        def create_widget(widget_data)
          post '/widgets', widget_data
        end
      end

      class MyGivenDriver < Kookaburra::GivenDriver
        def api
          MyAPIDriver.new(:app_host => initialization_options[:app_host])
        end

        def a_user(name)
          user = {'email' => 'bob@example.com', 'password' => '12345'}
          result = api.create_user(user)
          test_data.users[name] = result
        end

        def a_widget(name, attributes = {})
          widget = {'name' => 'Foo'}.merge(attributes)
          result = api.create_widget(widget)
          test_data.widgets[name] = result
        end
      end

      class SignInScreen < Kookaburra::UIDriver::UIComponent
        def component_path
          '/session/new'
        end

        def component_locator
          '#sign_in_screen'
        end

        def sign_in(user_data)
          fill_in 'Email:', :with => user_data['email']
          fill_in 'Password:', :with => user_data['password']
          click_button 'Sign In'
        end
      end

      class WidgetList < Kookaburra::UIDriver::UIComponent
        def component_path
          '/widgets'
        end

        def component_locator
          '#widget_list'
        end

        def widgets
          all('.widget_summary').map do |el|
            extract_widget_data(el)
          end
        end

        def last_widget_created
          element = find('.last_widget.created')
          extract_widget_data(element)
        end

        def choose_to_create_new_widget
          click_on 'New Widget'
        end

        def choose_to_delete_widget(widget_data)
          find("#delete_#{widget_data['id']}").click_button('Delete')
        end

        private

        def extract_widget_data(element)
          {
            'id' => element.find('.id').text,
            'name' => element.find('.name').text
          }
        end
      end

      class WidgetForm < Kookaburra::UIDriver::UIComponent
        def component_locator
          '#widget_form'
        end

        def submit(widget_data)
          fill_in 'Name:', :with => widget_data['name']
          click_on 'Save'
        end
      end

      class MyUIDriver < Kookaburra::UIDriver
        ui_component :sign_in_screen, SignInScreen
        ui_component :widget_list, WidgetList
        ui_component :widget_form, WidgetForm

        def sign_in(name)
          sign_in_screen.show
          sign_in_screen.sign_in(test_data.users[name])
        end

        def create_new_widget(name, attributes = {})
          widget_list.show
          widget_list.choose_to_create_new_widget
          widget_form.submit('name' => 'My Widget')
          test_data.widgets[name] = widget_list.last_widget_created
        end

        def delete_widget(name)
          widget_list.show
          widget_list.choose_to_delete_widget(test_data.widgets[name])
        end
      end

      before(:all) do
        @rack_server_port = 3339
        @rack_server_pid = fork do
          Rack::Server.start(
            :app => JsonApiApp.new,
            :server => :webrick,
            :Host => '127.0.0.1',
            :Port => @rack_server_port,
            :environment => 'production'
          )
        end
        sleep 1 # Give the server a chance to start up.
      end

      after(:all) do
        Process.kill(9, @rack_server_pid)
        Process.wait
      end

      it "runs the tests against the app" do
        server_error_detection = lambda { |browser|
          browser.has_css?('head title', :text => 'Internal Server Error')
        }

        k = Kookaburra.new({
          :ui_driver_class        => MyUIDriver,
          :given_driver_class     => MyGivenDriver,
          :app_host               => 'http://127.0.0.1:%d' % @rack_server_port,
          :browser                => Capybara::Session.new(:selenium),
          :server_error_detection => server_error_detection
        })

        k.given.a_user(:bob)
        k.given.a_widget(:widget_a)
        k.given.a_widget(:widget_b, :name => 'Foo')

        k.ui.sign_in(:bob)
        k.ui.widget_list.show
        k.ui.widget_list.widgets.should == k.get_data(:widgets).slice(:widget_a, :widget_b)

        k.ui.create_new_widget(:widget_c, :name => 'Bar')
        k.ui.widget_list.widgets.should == k.get_data(:widgets).slice(:widget_a, :widget_b, :widget_c)

        k.ui.delete_widget(:widget_b)
        k.ui.widget_list.widgets.should == k.get_data(:widgets).slice(:widget_a, :widget_c)
      end
    end
  end
end
