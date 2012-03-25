shared_examples_for :it_can_make_assertions do
  describe '#assert' do
    it 'returns true if the condition is truthy' do
      subject.send(:assert, true, "Shouldn't see this message").should == true
    end

    it 'raises a Kookaburra::AssertionFailed exception if the condition is not truthy' do
      lambda { subject.send(:assert, false, "False isn't true, dummy.") } \
        .should raise_error(Kookaburra::AssertionFailed, "False isn't true, dummy.")
    end
  end
end
