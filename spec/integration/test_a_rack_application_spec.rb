require 'kookaburra/test_helpers'
require 'kookaburra/api_driver'
require 'kookaburra/rack_app_server'
require 'capybara'
require 'capybara/webkit'
require 'uuid'

# These are required for the Rack app used for testing
require 'sinatra/base'
require 'json'

describe "testing a Rack application with Kookaburra" do
  include Kookaburra::TestHelpers

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
          widget_data[:id] = UUID.new.generate
          @@widgets << widget_data
          @@last_widget_created = widget_data
          request.accept.each do |type|
            case type.to_s
            when 'application/json'
              status 201
              headers 'Content-Type' => 'application/json'
              halt widget_data.to_json
            else
              halt redirect to('/widgets')
            end
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

        get '/error_page' do
          content = <<-EOF
            <html>
              <head>
                <title>Internal Server Error</title>
              </head>
              <body>
                <p>A Purposeful Error</p>
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

      class MyAPIClientDriver < Kookaburra::APIClientDriver
        def api
          MyAPIDriver.new(configuration)
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

        # Use default component locator value
        #
        # def component_locator
        #   '#sign_in_screen'
        # end

        def sign_in(user_data)
          fill_in 'Email:', :with => user_data['email']
          fill_in 'Password:', :with => user_data['password']
          click_button 'Sign In'
        end
      end

      class ErrorPage < Kookaburra::UIDriver::UIComponent
        def component_path
          '/error_page'
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
        ui_component :error_page, ErrorPage
        ui_component :sign_in_screen, SignInScreen
        ui_component :widget_list, WidgetList
        ui_component :widget_form, WidgetForm

        def sign_in(name)
          address_bar.go_to sign_in_screen
          sign_in_screen.sign_in(mental_model.users[name])
        end

        def error_on_purpose
          address_bar.go_to error_page
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

      app_server = Kookaburra::RackAppServer.new do
        JsonApiApp.new
      end

      before(:all) do
        app_server.boot

        Kookaburra.configure do |c|
          c.ui_driver_class = MyUIDriver
          c.given_driver_class = MyGivenDriver
          c.api_client_driver_class = MyAPIClientDriver
          c.app_host = 'http://127.0.0.1:%d' % app_server.port
          c.browser = Capybara::Session.new(:webkit)
          c.server_error_detection do |browser|
            browser.has_css?('head title', :text => 'Internal Server Error', :visible => false)
          end
        end
      end

      after(:all) do
        app_server.shutdown
      end

      before(:each) do
        given.a_user(:bob)
        given.a_widget(:widget_a)
        given.a_widget(:widget_b, :name => 'Foo')
      end

      it "runs the tests against the application's UI" do
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

      it "runs the tests against the applications's API" do
        pending "Requires Implementation of API client driver" do
          api_client.widgets.should == k.get_data(:widgets).values_at(:widget_a, :widget_b)
          api_client.widgets.should match_mental_model_of(:widgets)

          api_client.create_new_widget(:widget_c, :name => 'Bar')
          api_client.widgets.should == k.get_data(:widgets).values_at(:widget_a, :widget_b, :widget_c)
          api_client.widgets.should match_mental_model_of(:widgets)

          api_client.delete_widget(:widget_b)
          api_client.widgets.should == k.get_data(:widgets).values_at(:widget_a, :widget_c)
          api_client.widgets.should match_mental_model_of(:widgets)
        end
      end

      it "catches errors based on the server error detection handler" do
        expect { ui.error_on_purpose } \
          .to raise_error(Kookaburra::UnexpectedResponse)
      end
    end
  end
end
