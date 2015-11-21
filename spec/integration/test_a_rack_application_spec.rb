require 'spec_helper'
require 'kookaburra/test_helpers'
require 'kookaburra/api_client'
require 'kookaburra/rack_app_server'
require 'capybara'
require 'capybara/poltergeist'
require 'uuid'

require 'support/json_api_app_and_kookaburra_drivers'

describe "testing a Rack application with Kookaburra", :slow do
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
          c.api_driver_class = MyAPIDriver
          c.app_host = 'http://127.0.0.1:%d' % app_server.port
          c.browser = Capybara::Session.new(:poltergeist)
          c.server_error_detection do |browser|
            browser.has_css?('head title', :text => 'Internal Server Error', :visible => false)
          end
        end
      end

      after(:all) do
        app_server.shutdown
      end

      before(:each) do
        api.create_user(:bob)
        api.create_widget(:widget_a)
        api.create_widget(:widget_b, :name => 'Widget B')
      end

      define_method(:widgets) { get_data(:widgets) }

      it "runs the tests against the application's UI" do
        ui.sign_in(:bob)

        ui.view_widget_list
        expect(ui.widget_list.widgets).to include widgets[:widget_a]
        expect(ui.widget_list.widgets).to include widgets[:widget_b]

        ui.create_widget(:widget_c, :name => 'Bar')
        expect(ui.widget_list.widgets).to include widgets[:widget_a]
        expect(ui.widget_list.widgets).to include widgets[:widget_b]
        expect(ui.widget_list.widgets).to include widgets[:widget_c]

        ui.delete_widget(:widget_b)
        expect(ui.widget_list.widgets).to include widgets[:widget_a]
        expect(ui.widget_list.widgets).to include widgets[:widget_c]
        expect(ui.widget_list.widgets).to_not include widgets.deleted[:widget_b]
      end

      it "runs the tests against the applications's API" do
        expect(api.widgets).to include widgets[:widget_a]
        expect(api.widgets).to include widgets[:widget_b]

        api.create_widget(:widget_c, :name => 'Bar')
        expect(api.widgets).to include widgets[:widget_a]
        expect(api.widgets).to include widgets[:widget_b]
        expect(api.widgets).to include widgets[:widget_c]

        api.delete_widget(:widget_b)
        expect(api.widgets).to include widgets[:widget_a]
        expect(api.widgets).to include widgets[:widget_c]
        expect(api.widgets).to_not include widgets.deleted[:widget_b]
      end

      it "catches errors based on the server error detection handler" do
        expect { ui.error_on_purpose } \
          .to raise_error(Kookaburra::UnexpectedResponse)
      end
    end
  end
end
