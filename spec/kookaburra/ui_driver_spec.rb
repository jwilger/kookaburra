require 'kookaburra/ui_driver'
require 'support/shared_examples/it_has_a_dependency_accessor'
require 'support/shared_examples/it_can_make_assertions'

describe Kookaburra::UIDriver do
  describe '.ui_component' do
    it 'adds an accessor method for the named component that defaults to an instance of the specified class' do
      foo_component_class = mock(Class)
      foo_component_class.should_receive(:new) \
        .with(:browser => :a_browser, :server_error_detection => :server_error_detection,
              :app_host => :a_url) \
        .and_return(:a_foo_component)

      ui_driver_class = Class.new(Kookaburra::UIDriver) do
        ui_component :foo, foo_component_class
      end

      ui = ui_driver_class.new(:browser => :a_browser, :server_error_detection => :server_error_detection,
                               :app_host => :a_url)
      ui.foo.should == :a_foo_component
    end
  end

  describe '.ui_driver' do
    it 'adds an accessor method for the named driver that defaults to an instance of the specified class' do
      foo_driver_class = mock(Class)
      foo_driver_class.should_receive(:new) \
        .with(:browser => :a_browser, :server_error_detection => :server_error_detection,
              :app_host => :a_url, :mental_model => :a_mental_model) \
        .and_return(:a_foo_driver)

      ui_driver_class = Class.new(Kookaburra::UIDriver) do
        ui_driver :foo, foo_driver_class
      end

      ui = ui_driver_class.new(:browser => :a_browser, :server_error_detection => :server_error_detection,
                               :app_host => :a_url, :mental_model => :a_mental_model)
      ui.foo.should == :a_foo_driver
    end
  end

  describe 'dependency accessors' do
    let(:subject_class) { Kookaburra::UIDriver }

    it_behaves_like :it_has_a_dependency_accessor, :mental_model
  end

  it_behaves_like :it_can_make_assertions
end
