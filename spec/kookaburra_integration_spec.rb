require 'kookaburra'
require 'rack'
require 'capybara'

describe 'Kookaburra Integration' do
  describe "testing a Rack application" do
    describe "with an HTML interface" do
      describe "with a JSON API" do
        it "runs the tests against the app" do
          # Set up GivenDriver for this test
          my_given_driver_class = Class.new(Kookaburra::GivenDriver) do
            def a_user(name)
            end

            def a_widget(name, attributes = {})
            end
          end
          given = my_given_driver_class.new

          # Set up UIDriver for this test
          sign_in_screen_class = Class.new(Kookaburra::UIDriver::UIComponent) do
            def component_path
              '/session/new'
            end
          end

          my_ui_driver_class = Class.new(Kookaburra::UIDriver) do
            ui_component :sign_in_screen, sign_in_screen_class

            def sign_in(name)
              sign_in_screen.show
              sign_in_screen.sign_in(test_data.users[name])
            end
          end
          ui = my_ui_driver_class.new

          given.a_user(:bob)
          given.a_widget(:widget_a)
          given.a_widget(:widget_b, :name => 'Foo')

          pending 'WIP' do
            ui.sign_in(:bob)
            ui.widget_list.show
            ui.widget_list.widgets.should == [k.widgets[:widget_a], k.widgets[:widget_b]]

            ui.create_new_widget(:widget_c, :name => 'Bar')
            ui.widget_list.widgets.should == [k.widgets[:widget_a], k.widgets[:widget_b], k.widgets[:widget_c]]

            ui.delete_widget(:widget_b)
            ui.widget_list.widgets.should == [k.widgets[:widget_a], k.widgets[:widget_c]]
          end
        end
      end
    end
  end
end
