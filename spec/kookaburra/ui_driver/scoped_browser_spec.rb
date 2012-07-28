require 'kookaburra/ui_driver/scoped_browser'

describe Kookaburra::UIDriver::ScopedBrowser do
  it 'forwards all method calls to the browser but scopes them to the component locator' do
    browser = mock('Browser')
    browser.should_receive(:within).with('#a_component_locator').and_yield
    browser.should_receive(:some_other_method).with(:foo)
    subject = Kookaburra::UIDriver::ScopedBrowser.new(browser, lambda { '#a_component_locator' })
    subject.some_other_method(:foo)
  end
end
