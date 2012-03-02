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

          # Set up UIDriver for this test
          my_app = Object.new.tap do |a|
            def a.call(*args)
              [200, {}, '']
            end
          end

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

          k = Kookaburra.new(:ui_driver_class => my_ui_driver_class,
                            :given_driver_class => my_given_driver_class,
                            :browser => Capybara::Session.new(:rack_test, my_app))

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
