shared_examples_for :it_has_a_dependency_accessor do |accessor_name|
  describe accessor_name.to_s do
    it "returns the #{accessor_name} object passed in at initialization" do
      component = subject_class.new(accessor_name => :thing)
      component.send(accessor_name).should == :thing
    end

    context "when the #{accessor_name} object is not set" do
      it 'raises a StandardError' do
        component = subject_class.new
        lambda { component.send(accessor_name) } \
          .should raise_error(StandardError)
      end

      it "explains that the #{accessor_name} was not set on initialiation" do
        subject_class.stub!(:name => 'Foo')
        component = subject_class.new
        begin
          component.send(accessor_name)
        rescue StandardError => e
          e.message.should == "No #{accessor_name} object was set on Foo initialization."
        end
      end
    end
  end
end
