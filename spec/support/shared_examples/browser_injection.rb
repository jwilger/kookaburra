shared_examples_for :browser_injection do
  describe '#browser' do
    it 'returns the browser object passed in at initialization' do
      browser = Object.new
      component = subject_class.new(:browser => browser)
      component.send(:browser).should === browser
    end

    context 'when the browser object is not set' do
      it 'raises a StandardError' do
        component = subject_class.new
        lambda { component.send(:browser) } \
          .should raise_error(StandardError)
      end

      it 'explains that the browser was not set on initialiation' do
        subject_class.stub!(:name => 'Foo')
        component = subject_class.new
        begin
          component.send(:browser)
        rescue StandardError => e
          e.message.should == 'No browser object was set on Foo initialization.'
        end
      end
    end
  end
end
