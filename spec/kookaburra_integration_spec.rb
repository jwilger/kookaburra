require 'kookaburra'
require 'capybara'
require 'sinatra/base'
require 'active_support/hash_with_indifferent_access'

describe 'Kookaburra Integration' do
  describe "testing a Rack application" do
    describe "with an HTML interface" do
      describe "with a JSON API" do
        require 'kookaburra/json_api_driver'
        class MyAPIDriver < Kookaburra::JsonApiDriver
          def create_user(user_data)
            post '/users', user_data
          end

          def create_widget(widget_data)
            post '/widgets', widget_data
          end
        end

        class MyGivenDriver < Kookaburra::GivenDriver
          def a_user(name)
            user = { :username => 'bob', :password => '12345' }
            result = api.create_user(user)
            test_data.users[name] = result
          end

          def a_widget(name, attributes = {})
            widget = {:name => 'Foo'}.merge(attributes)
            result = api.create_widget(widget)
            test_data.widgets[name] = result
          end
        end

        class SignInScreen < Kookaburra::UIDriver::UIComponent
          def component_path
            '/session/new'
          end

          def sign_in(user_data)
            browser.fill_in :email, :with => user_data[:email]
            browser.fill_in :password, :with => user_data[:password]
            browser.click_button 'Sign In'
          end
        end

        class WidgetList < Kookaburra::UIDriver::UIComponent
          def component_path
            '/widgets'
          end

          def widgets
            browser.all('.widget_summary').map do |el|
              {
                :id => el.find('.id').text,
                :name => el.find('.name').text
              }
            end
          end
        end

        class MyUIDriver < Kookaburra::UIDriver
          ui_component :sign_in_screen, SignInScreen
          ui_component :widget_list, WidgetList

          def sign_in(name)
            sign_in_screen.show
            sign_in_screen.sign_in(test_data.users[name])
          end
        end

        class TestRackApp < Sinatra::Base
          set :raise_errors, true
          set :show_exceptions, false

          def parse_json_req_body
            request.body.rewind
            HashWithIndifferentAccess.new(ActiveSupport::JSON.decode(request.body.read))
          end

          post '/users' do
            user_data = parse_json_req_body
            @@users ||= {}
            @@users[user_data['email']] = user_data
            status 201
            headers 'Content-Type' => 'application/json'
            body user_data.to_json
          end

          post '/session' do
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

          post '/widgets' do
            widget_data = parse_json_req_body
            @@widgets ||= []
            widget_data[:id] = `uuidgen`.strip
            @@widgets << widget_data
            status 201
            headers 'Content-Type' => 'application/json'
            body widget_data.to_json
          end

          get '/widgets' do
            @@widgets ||= []
            content = ''
            content << <<-EOF
              <html>
                <head>
                  <title>Widgets</title>
                </head>
                <body>
                  <div id="widget_list">
                    <ul>
                    EOF
                    @@widgets.each do |w|
                      content << <<-EOF
                      <li class="widget_summary">
                        <span class="id">#{w[:id]}</span>
                        <span class="name">#{w[:name]}</span>
                      </li>
                      EOF
                    end
                    content << <<-EOF
                    </ul>
                  </div>
                </body>
              </html>
            EOF
            body content
          end
        end


        it "runs the tests against the app" do
          my_app = TestRackApp.new

          k = Kookaburra.new({
            :ui_driver_class    => MyUIDriver,
            :given_driver_class => MyGivenDriver,
            :api_driver_class   => MyAPIDriver,
            :browser            => Capybara::Session.new(:rack_test, my_app)
          })

          k.given.a_user(:bob)
          k.given.a_widget(:widget_a)
          k.given.a_widget(:widget_b, :name => 'Foo')

          k.ui.sign_in(:bob)
          k.ui.widget_list.show
          k.ui.widget_list.widgets.should == k.get_data(:widgets)[:widget_a, :widget_b]
          pending 'WIP' do

            k.ui.create_new_widget(:widget_c, :name => 'Bar')
            k.ui.widget_list.widgets.should == k.get_data(:widgets).slice(:widget_a, :widget_b, :widget_c)

            k.ui.delete_widget(:widget_b)
            k.ui.widget_list.widgets.should == k.get_data(:widgets).slice(:widget_a, :widget_c)
          end
        end
      end
    end
  end
end
