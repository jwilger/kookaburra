require 'spec_helper'
require 'kookaburra/test_helpers'

describe Kookaburra::TestHelpers do
  subject {
    Object.new.tap do |o|
      o.extend Kookaburra::TestHelpers
    end
  }

  let(:k_kookaburra) {
    double(:k_kookaburra, api: k_api, ui: k_ui, get_data: k_data)
  }
  let(:k_api) { double(:k_api) }
  let(:k_ui) { double(:k_ui) }
  let(:k_data) { double(:k_data) }

  before(:each) do
    allow(Kookaburra).to receive(:new) { k_kookaburra }
  end

  shared_examples_for 'it has no individual applications configured' do
    it 'forwards #api to the main Kookaburra instance' do
      expect(subject.api).to equal k_api
    end

    it 'forwards #ui to the main Kookaburra instance' do
      expect(subject.ui).to equal k_ui
    end

    it 'forwards #get_data to the main Kookaburra instance' do
      expect(subject.get_data).to equal k_data
    end
  end

  context "when no individual applications are configured" do
    it_behaves_like 'it has no individual applications configured'
  end

  context "when individual applications are configured" do
    before(:each) do
      Kookaburra.configure do |c|
        c.application(:foo)
        c.application(:bar)
      end
    end

    specify '#api raises an AmbiguousDriverError' do
      expect{ subject.api }.to raise_error Kookaburra::AmbiguousDriverError
    end

    specify '#ui raises an AmbiguousDriverError' do
      expect{ subject.api }.to raise_error Kookaburra::AmbiguousDriverError
    end

    specify '#get_data is forwarded to the main Kookaburra instance' do
      expect(subject.get_data).to equal k_data
    end

    it 'has a helper method for each configured application' do
      expect(subject.foo).to equal Kookaburra.configuration.applications[:foo]
      expect(subject.bar).to equal Kookaburra.configuration.applications[:bar]
    end

    context "and then Kookaburra is reconfigured" do
      before(:each) do
        Kookaburra.configure {}
      end
      
      it_behaves_like 'it has no individual applications configured'

      it 'does not have helper methods for the previously configured applications' do
        expect{ subject.foo }.to raise_error(NameError)
        expect{ subject.bar }.to raise_error(NameError)
      end
    end
  end
end
