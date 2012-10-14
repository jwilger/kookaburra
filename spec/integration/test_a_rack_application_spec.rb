require 'kookaburra/test_helpers'
require 'kookaburra/api_driver'
require 'capybara'
require 'thwait'
require 'find_a_port'

# These are required for the Rack app used for testing
require 'sinatra/base'
require 'json'

# The server port to which the application server will attach
APP_PORT = FindAPort.available_port

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
          JSON.parse(request.body.read, :symbolize_names => true)
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
                          {:name => params['name']}
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

      class MyAPIDriver < Kookaburra::APIDriver
        encode_with { |data| JSON.dump(data) }
        decode_with { |data| JSON.parse(data) }
        header 'Content-Type', 'application/json'
        header 'Accept', 'application/json'

        def create_user(user_data)
          post '/users', user_data
        end

        def create_widget(widget_data)
          post '/widgets', widget_data
        end
      end

      class MyGivenDriver < Kookaburra::GivenDriver
        def api
          MyAPIDriver.new(configuration)
        end

        def a_user(name)
          user = {'email' => 'bob@example.com', 'password' => '12345'}
          result = api.create_user(user)
          mental_model.users[name] = result
        end

        def a_widget(name, attributes = {})
          widget = {'name' => 'Foo'}.merge(attributes)
          result = api.create_widget(widget)
          mental_model.widgets[name] = result
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

      class WidgetDataContainer
        def initialize(element)
          @element = element
        end

        def to_hash
          {
            'id' => @element.find('.id').text,
            'name' => @element.find('.name').text
          }
        end
      end

      class LastWidgetCreated < Kookaburra::UIDriver::UIComponent
        def component_locator
          @options[:component_locator]
        end

        def data
          raise "Foo" unless visible?
          WidgetDataContainer.new(self).to_hash
        end
      end

      class WidgetList < Kookaburra::UIDriver::UIComponent
        ui_component :last_widget_created, LastWidgetCreated, :component_locator => '#widget_list .last_widget.created'

        def component_path
          '/widgets'
        end

        def component_locator
          '#widget_list'
        end

        def widgets
          all('.widget_summary').map do |el|
            WidgetDataContainer.new(el).to_hash
          end
        end

        def choose_to_create_new_widget
          click_on 'New Widget'
        end

        def choose_to_delete_widget(widget_data)
          find("#delete_#{widget_data['id']}").click_button('Delete')
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
          address_bar.go_to sign_in_screen
          sign_in_screen.sign_in(mental_model.users[name])
        end

        def view_widget_list
          address_bar.go_to widget_list
        end

        def create_new_widget(name, attributes = {})
          assert widget_list.visible?, "Widget list is not visible!"
          widget_list.choose_to_create_new_widget
          widget_form.submit('name' => 'My Widget')
          mental_model.widgets[name] = widget_list.last_widget_created.data
        end

        def delete_widget(name)
          assert widget_list.visible?, "Widget list is not visible!"
          widget_list.choose_to_delete_widget(mental_model.widgets.delete(name))
        end
      end

      before(:all) do
        start_server = lambda {
          Capybara.server_port = APP_PORT
          Capybara::Server.new(JsonApiApp.new).boot
          ThreadsWait.all_waits(Thread.list)
        }
        if defined?(JRUBY_VERSION)
          # Can't `fork` in JRuby. This doesn't provide the state
          # isolation that you get with forking (AFAIK, I'm no JVM
          # expert, though), but it lets the tests run and pass.
          Thread.new { start_server.call }
        else
          @rack_server_pid = fork do
            start_server.call
          end
        end
        sleep 1 # Give the server a chance to start up.
      end

      after(:all) do
        unless defined?(JRUBY_VERSION)
          Process.kill(9, @rack_server_pid)
          Process.wait
        end
      end

      it "runs the tests against the app" do
        Kookaburra.configure do |c|
          c.ui_driver_class = MyUIDriver
          c.given_driver_class = MyGivenDriver
          c.app_host = 'http://127.0.0.1:%d' % APP_PORT
          c.browser = Capybara::Session.new(:selenium)
          c.server_error_detection do |browser|
            browser.has_css?('head title', :text => 'Internal Server Error')
          end
        end

        extend Kookaburra::TestHelpers

        given.a_user(:bob)
        given.a_widget(:widget_a)
        given.a_widget(:widget_b, :name => 'Foo')

        ui.sign_in(:bob)
        ui.view_widget_list

        # The following two lines are two different ways to shave the yak, but
        # the second one does more to match against the full state of the mental
        # model, provides better failure messages, and is shorter.
        ui.widget_list.widgets.should == k.get_data(:widgets).values_at(:widget_a, :widget_b)
        ui.widget_list.widgets.should match_mental_model_of(:widgets)

        ui.create_new_widget(:widget_c, :name => 'Bar')


        # As above, these are equivalent, but the second line is preferred.
        ui.widget_list.widgets.should == k.get_data(:widgets).values_at(:widget_a, :widget_b, :widget_c)
        ui.widget_list.widgets.should match_mental_model_of(:widgets)

        ui.delete_widget(:widget_b)

        # As above, these are equivalent, but the second line is preferred.
        ui.widget_list.widgets.should == k.get_data(:widgets).values_at(:widget_a, :widget_c)
        ui.widget_list.widgets.should match_mental_model_of(:widgets)
      end
    end
  end
end
