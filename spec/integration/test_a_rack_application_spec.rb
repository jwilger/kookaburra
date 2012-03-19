require 'kookaburra'
require 'capybara'
require 'sinatra/base'
require 'active_support/hash_with_indifferent_access'

describe "testing a Rack application with Kookaburra" do
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
        def api
          MyAPIDriver.new(:base_url => initialization_options[:base_url])
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
        `rake rackup:json_api_app:start`
      end

      after(:all) do
        `rake rackup:json_api_app:stop`
      end

      it "runs the tests against the app" do
        server_error_detection = lambda { |browser|
          browser.has_css?('h1', :text => 'Internal Server Error')
        }

        k = Kookaburra.new({
          :ui_driver_class        => MyUIDriver,
          :given_driver_class     => MyGivenDriver,
          :base_url               => 'http://127.0.0.1:4567',
          :browser                => Capybara::Session.new(:selenium),
          :server_error_detection => server_error_detection
        })

        pending "WIP" do
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
end
