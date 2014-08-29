require 'kookaburra/test_helpers'
require 'kookaburra/api_client'
require 'kookaburra/rack_app_server'
require 'capybara'
require 'capybara/webkit'
require 'uuid'

require 'support/json_api_app_and_kookaburra_drivers'

describe "testing a Rack application with Kookaburra" do
  include Kookaburra::TestHelpers

  describe "with an HTML interface" do
    describe "with a JSON API" do
      app_server = Kookaburra::RackAppServer.new do
        JsonApiApp.new
      end

      before(:all) do
        app_server.boot

        Kookaburra.configure do |c|
          c.ui_driver_class = MyUIDriver
          c.given_driver_class = MyGivenDriver
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

      define_method(:widgets) { k.get_data(:widgets) }

      it "runs the tests against the application's UI" do
        ui.sign_in(:bob)

        ui.view_widget_list
        expect(ui.widget_list.widgets).to include widgets[:widget_a]
        expect(ui.widget_list.widgets).to include widgets[:widget_b]

        ui.create_new_widget(:widget_c, :name => 'Bar')
        expect(ui.widget_list.widgets).to include widgets[:widget_a]
        expect(ui.widget_list.widgets).to include widgets[:widget_b]
        expect(ui.widget_list.widgets).to include widgets[:widget_c]

        ui.delete_widget(:widget_b)
        expect(ui.widget_list.widgets).to include widgets[:widget_a]
        expect(ui.widget_list.widgets).to include widgets[:widget_c]
        expect(ui.widget_list.widgets).to_not include widgets.deleted[:widget_b]
      end

      it "runs the tests against the applications's API" do
        expect(given.widgets).to include widgets[:widget_a]
        expect(given.widgets).to include widgets[:widget_b]

        given.create_new_widget(:widget_c, :name => 'Bar')
        expect(given.widgets).to include widgets[:widget_a]
        expect(given.widgets).to include widgets[:widget_b]
        expect(given.widgets).to include widgets[:widget_c]

        given.delete_widget(:widget_b)
        expect(given.widgets).to include widgets[:widget_a]
        expect(given.widgets).to include widgets[:widget_c]
        expect(given.widgets).to_not include widgets.deleted[:widget_b]
      end

      it "catches errors based on the server error detection handler" do
        expect { ui.error_on_purpose } \
          .to raise_error(Kookaburra::UnexpectedResponse)
      end
    end
  end
end
