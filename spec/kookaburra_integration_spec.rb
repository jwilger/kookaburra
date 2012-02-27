require 'kookaburra'
require 'rack'
require 'capybara'

describe 'Kookaburra Integration' do
  describe "testing a Rack application" do
    describe "with an HTML interface" do
      describe "with a JSON API" do
        it "runs the tests against the app" do
          my_api_driver_class = Class.new(Kookaburra::APIDriver)
          my_given_driver_class = Class.new(Kookaburra::GivenDriver)
          my_ui_driver_class = Class.new(Kookaburra::UIDriver)
          my_app = Object.new
          my_session = Capybara::Session.new(:javascript, my_app)
          my_api_driver = my_api_driver_class.new(:app => my_app)
          my_given_driver = my_given_driver_class.new(:api_driver => my_api_driver)
          my_ui_driver = my_ui_driver_class.new(:session => my_session)
          k = Kookaburra.new(:given_driver => my_given_driver, :ui_driver => my_ui_driver)

          pending 'WIP' do
            k.given.a_user(:bob)
            k.given.a_widget(:widget_a)
            k.given.a_widget(:widget_b, :name => 'Foo')

            k.ui.sign_in(:bob)
            k.ui.navigate_to :widget_list
            k.ui.widget_list.widgets.should == [k.widgets[:widget_a], k.widgets[:widget_b]]

            k.ui.create_new_widget(:widget_c, :name => 'Bar')
            k.ui.widget_list.widgets.should == [k.widgets[:widget_a], k.widgets[:widget_b], k.widgets[:widget_c]]

            k.ui.delete_widget(:widget_b)
            k.ui.widget_list.widgets.should == [k.widgets[:widget_a], k.widgets[:widget_c]]
          end
        end
      end
    end
  end
end
