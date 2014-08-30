shared_examples_for :it_can_have_ui_components do |subject_class|
  describe '.ui_component' do
    it 'adds an accessor method for the named component that defaults to an instance of the specified class' do
      configuration = double('Kookaburra::Configuration').as_null_object
      foo_component_class = double(Class)
      allow(foo_component_class).to receive(:new) \
        .with(configuration, :option => :value) \
        .and_return(:a_foo_component)

      component_container_class = Class.new(subject_class) do
        ui_component :foo, foo_component_class, :option => :value
      end

      component_container = component_container_class.new(configuration)
      expect(component_container.foo).to eq :a_foo_component
    end
  end
end
