require File.join(File.dirname(__FILE__), *%w[requires])

module Kookaburra
  def self.drivers
    test_data = Kookaburra::TestData.new
    api_driver = Kookaburra::APIDriver.new({
      :app       => Capybara.app,
      :test_data => test_data,
    })
    given_driver = Kookaburra::GivenDriver.new({
      :api_driver => api_driver,
    })
    ui_driver = Kookaburra::UIDriver.new({
      :browser   => Capybara.current_session,
      :test_data => test_data,
    })
    { :api_driver => api_driver, :given_driver => given_driver, :ui_driver => ui_driver }
  end
end
