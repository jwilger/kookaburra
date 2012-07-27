require 'kookaburra/ui_driver'
require 'support/shared_examples/it_has_a_dependency_accessor'
require 'support/shared_examples/it_can_make_assertions'
require 'support/shared_examples/it_can_have_ui_components'

describe Kookaburra::UIDriver do
  it_behaves_like :it_can_have_ui_components, Kookaburra::UIDriver

  describe '.ui_driver' do
    it 'adds an accessor method for the named driver that defaults to an instance of the specified class' do
      foo_driver_class = mock(Class)
      foo_driver_class.should_receive(:new) \
        .with(:configuration) \
        .and_return(:a_foo_driver)

      ui_driver_class = Class.new(Kookaburra::UIDriver) do
        ui_driver :foo, foo_driver_class
      end

      ui = ui_driver_class.new(:configuration)
      ui.foo.should == :a_foo_driver
    end
  end

  describe '#url' do
    it 'returns the configured app_host' do
      config = stub('Configuration', :app_host => 'http://my.example.com')
      driver = Kookaburra::UIDriver.new(config)
      driver.url.should == 'http://my.example.com'
    end
  end

  it_behaves_like :it_can_make_assertions do
    let(:subject) { Kookaburra::UIDriver.new(stub('Configuration')) }
  end
end
