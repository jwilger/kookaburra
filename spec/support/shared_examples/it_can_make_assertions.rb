shared_examples_for :it_can_make_assertions do
  describe '#assert' do
    it 'returns true if the condition is truthy' do
      expect(subject.send(:assert, true, "Shouldn't see this message")).to eq true
    end

    it 'raises a Kookaburra::AssertionFailed exception if the condition is not truthy' do
      expect{ subject.send(:assert, false, "False isn't true, dummy.") }.to \
        raise_error(Kookaburra::AssertionFailed, "False isn't true, dummy.")
    end
  end
end
