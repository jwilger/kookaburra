require 'spec_helper'
require 'kookaburra/test_helpers'

describe 'Kookaburra.test_helpers', :focus do
  context "when only one application is configured" do
    include Kookaburra.test_helpers

    before(:all) do
      Kookaburra.configure do |c|
        c.api_driver_class = Kookaburra::APIDriver
        c.ui_driver_class    = Kookaburra::UIDriver
      end
    end

    after(:all) do
      Kookaburra.forget_configuration!
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

  context "when multiple applications are configured" do
    include Kookaburra.test_helpers

    before(:all) do
      Kookaburra.configure do |c|
        c.application(:app_1) do |a|
        end

        c.application(:app_2) do |a|
        end
      end
    end

    after(:all) do
      Kookaburra.forget_configuration!
    end

    it 'returns a seperate Kookaburra instance for each defined application' do
      expect(app_1).to be_kind_of(Kookaburra)
      expect(app_2).to be_kind_of(Kookaburra)
      expect(app_1).to_not equal app_2
    end
  end
end
