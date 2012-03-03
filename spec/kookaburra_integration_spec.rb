require 'kookaburra'
require 'rack'
require 'capybara'

describe 'Kookaburra Integration' do
  describe "testing a Rack application" do
    describe "with an HTML interface" do
      describe "with a JSON API" do
        require 'kookaburra/json_api_driver'
        class MyAPIDriver < Kookaburra::JsonApiDriver
          def create_user(user_data)
            post '/users', user_data
          end
        end

        class MyGivenDriver < Kookaburra::GivenDriver
          def a_user(name)
            user = test_data.default(:user)  # => { :username => 'bob', :password => '12345' }
            result = api.create_user(user)
            test_data.users[name] = result
          end

          def a_widget(name, attributes = {})
          end
        end

        class MySignInScreen < Kookaburra::UIDriver::UIComponent
          def component_path
            '/session/new'
          end

          def sign_in(user_data)
            browser.fill_in :email, :with => user_data[:email]
            browser.fill_in :password, :with => user_data[:password]
            browser.click_button 'Log In'
          end
        end

        class MyUIDriver < Kookaburra::UIDriver
          ui_component :sign_in_screen, MySignInScreen

          def sign_in(name)
            sign_in_screen.show
            sign_in_screen.sign_in(test_data.users[name])
          end
        end


        it "runs the tests against the app" do
          my_app = Object.new.tap do |a|
            def a.call(*args)
              [201, {}, '{"foo":"bar"}']
            end
          end

          k = Kookaburra.new({
            :ui_driver_class    => MyUIDriver,
            :given_driver_class => MyGivenDriver,
            :api_driver_class   => MyAPIDriver,
            :browser            => Capybara::Session.new(:rack_test, my_app)
          })

          k.given.a_user(:bob)
          k.given.a_widget(:widget_a)
          k.given.a_widget(:widget_b, :name => 'Foo')

          pending 'WIP' do
            k.ui.sign_in(:bob)
            k.ui.widget_list.show
            k.ui.widget_list.should have_only(k.widgets[:widget_a], k.widgets[:widget_b])

            k.ui.create_new_widget(:widget_c, :name => 'Bar')
            k.ui.widget_list.should have_only(k.widgets[:widget_a], k.widgets[:widget_b], k.widgets[:widget_c])

            k.ui.delete_widget(:widget_b)
            k.ui.widget_list.should have_only(k.widgets[:widget_a], k.widgets[:widget_c])
          end
        end
      end
    end
  end
end
