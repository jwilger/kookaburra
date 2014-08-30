shared_examples_for :it_has_a_dependency_accessor do |accessor_name|
  describe accessor_name.to_s do
    it "returns the #{accessor_name} object as assigned" do
      subject.send("#{accessor_name}=", :thing)
      expect(subject.send(accessor_name)).to eq :thing
    end

    context "when the #{accessor_name} object is not set" do
      it 'raises a StandardError' do
        expect{ subject.send(accessor_name) }.to raise_error(StandardError)
      end

      it "explains that the #{accessor_name} was not set on initialiation" do
        begin
          subject.send(accessor_name)
        rescue StandardError => e
          expect(e.message).to eq "No #{accessor_name} object was set on #{subject.class.name} initialization."
        end
      end
    end
  end
end
