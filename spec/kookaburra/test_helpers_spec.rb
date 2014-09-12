require 'spec_helper'
require 'kookaburra/test_helpers'

describe Kookaburra::TestHelpers do
  include Kookaburra::TestHelpers

  context "when no individual applications are configured" do
    before(:each) do
      Kookaburra.configure do |c|
        c.api_driver_class = Kookaburra::APIDriver
        c.ui_driver_class    = Kookaburra::UIDriver
      end
    end

    describe "#k" do
      it "returns an instance of Kookaburra" do
        expect(k).to be_kind_of(Kookaburra)
      end

      it "memoizes" do
        a = k; b = k
        expect(a).to equal(b)
      end
    end

    describe "methods delegated to #k" do
      it "includes #api" do
        expect(k).to receive(:api)
        api
      end

      it "includes #ui" do
        expect(k).to receive(:ui)
        ui
      end
    end
  end

  context "when individual applications are configured" do
    before(:each) do
      Kookaburra.configure do |c|
        c.application(:foo)
        c.application(:bar)
      end
    end

    describe '#k' do
      it 'raises an AmbiguousDriverError' do
        expect{ k }.to raise_error Kookaburra::AmbiguousDriverError
      end
    end

    it 'has a helper method for each configured application' do
      expect(foo).to equal Kookaburra.configuration.applications[:foo]
      expect(bar).to equal Kookaburra.configuration.applications[:bar]
    end

    context "and then Kookaburra is reconfigured" do
      before(:each) do
        Kookaburra.configure {}
      end
      
      describe '#k' do
        it 'works again' do
          expect{ k }.to_not raise_error
        end

        it 'does not have helper methods for the previously configured applications' do
          expect{ foo }.to raise_error(NameError)
          expect{ bar }.to raise_error(NameError)
        end
      end
    end
  end
end
