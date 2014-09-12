require 'spec_helper'
require 'kookaburra/test_helpers'
require 'kookaburra/rack_app_server'
require 'capybara'
require 'capybara/webkit'
require 'uuid'

require 'support/json_api_app_and_kookaburra_drivers'

describe 'testing multiple applications', :slow do
  include Kookaburra::TestHelpers

  OtherJsonApiApp = Class.new(JsonApiApp)
  MyOtherUIDriver = Class.new(MyUIDriver)
  MyOtherAPIDriver = Class.new(MyAPIDriver)

  app_server_1 = Kookaburra::RackAppServer.new do
    JsonApiApp.new
  end

  app_server_2 = Kookaburra::RackAppServer.new do
    OtherJsonApiApp.new
  end

  before(:all) do
    app_server_1.boot
    app_server_2.boot

    Kookaburra.configure do |c|
      c.application(:app_1) do |a|
        a.ui_driver_class = MyUIDriver
        a.api_driver_class = MyAPIDriver
        a.app_host = 'http://127.0.0.1:%d' % app_server_1.port
      end
      c.application(:app_2) do |a|
        a.ui_driver_class = MyOtherUIDriver
        a.api_driver_class = MyOtherAPIDriver
        a.app_host = 'http://127.0.0.1:%d' % app_server_2.port
      end
      c.browser = Capybara::Session.new(:webkit)
      c.server_error_detection do |browser|
        browser.has_css?('head title', :text => 'Internal Server Error', :visible => false)
      end
    end
  end

  after(:all) do
    app_server_1.shutdown
    app_server_2.shutdown
  end

  specify 'once you have defined multiple apps, the top-level #api and #ui methods raise errors' do
    expect { api } .to raise_error( Kookaburra::AmbiguousDriverError )
    expect { ui }  .to raise_error( Kookaburra::AmbiguousDriverError )
  end

  context "with different data in each app" do
    before(:each) do
      app_1.api.create_user(:bob)
      app_2.api.create_user(:sue)
      app_1.api.create_widget(:widget_a)
      app_2.api.create_widget(:widget_b)
    end

    let(:widgets) { get_data(:widgets) }

    it 'can speak to both application APIs' do
      expect(app_1.api.widgets).to include widgets[:widget_a]
      expect(app_1.api.widgets).not_to include widgets[:widget_b]

      expect(app_2.api.widgets).not_to include widgets[:widget_a]
      expect(app_2.api.widgets).to include widgets[:widget_b]
    end

    it 'can speak to both application UIs' do
        app_1.ui.sign_in(:bob)
        app_1.ui.view_widget_list
        expect(app_1.ui.widget_list.widgets).to include widgets[:widget_a]
        expect(app_1.ui.widget_list.widgets).to_not include widgets[:widget_b]

        app_2.ui.sign_in(:sue)
        app_2.ui.view_widget_list
        expect(app_2.ui.widget_list.widgets).to_not include widgets[:widget_a]
        expect(app_2.ui.widget_list.widgets).to include widgets[:widget_b]
    end

    it 'shares a single browser session' do
      app_1.ui.sign_in(:bob)
      app_1.ui.view_widget_list
      app_2.ui.sign_in(:sue)
      expect(app_1.ui.widget_list).to be_not_visible
      app_1.ui.view_widget_list
      expect(app_1.ui.widget_list).to be_visible
    end
  end
end
