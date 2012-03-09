require 'kookaburra/ui_driver/scoped_browser'

describe Kookaburra::UIDriver::ScopedBrowser do
  describe '#method_missing' do
    it 'forwards the method call to the browser object after limiting it to the component locator scope' do
      browser = mock('Capybara::Session')
      component_scope = Kookaburra::UIDriver::ScopedBrowser.new(browser, '#my_component')
      in_within_block = false
      browser.should_receive(:within) do |locator_scope, &block|
        locator_scope.should == '#my_component'
        in_within_block = true
        result = block.call
        in_within_block = false
        result
      end

      browser.should_receive(:find) do |locator|
        locator.should == '.some_button'
        in_within_block.should == true
        :an_element
      end

      component_scope.find('.some_button').should == :an_element
    end
  end
end
