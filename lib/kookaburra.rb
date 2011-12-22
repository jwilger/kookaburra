base_path = File.expand_path(File.join(File.dirname(__FILE__), *%w[kookaburra]))
%w[api_driver given_driver test_data ui_driver world_setup].each do |file|
  require File.join(base_path, file)
end


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
