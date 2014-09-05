require 'spec_helper'
require 'kookaburra/test_helpers'

describe 'Kookaburra.test_helpers', :focus do
  context "when only one application is configured" do
    include Kookaburra::TestHelpers

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
    include Kookaburra::TestHelpers

    App_1_APIDriver = Class.new(Kookaburra::APIDriver)
    App_2_APIDriver = Class.new(Kookaburra::APIDriver)
    App_1_UIDriver = Class.new(Kookaburra::UIDriver)
    App_2_UIDriver = Class.new(Kookaburra::UIDriver)

    before(:all) do
      Kookaburra.configure do |c|
        c.application(:app_1) do |a|
          a.api_driver_class = App_1_APIDriver
          a.ui_driver_class = App_1_UIDriver
        end

        c.application(:app_2) do |a|
          a.api_driver_class = App_2_APIDriver
          a.ui_driver_class = App_2_UIDriver
        end
      end
    end

    after(:all) do
      Kookaburra.forget_configuration!
    end

    it 'returns a separate Kookaburra instance for each defined application' do
      expect(app_1).to be_kind_of(Kookaburra)
      expect(app_2).to be_kind_of(Kookaburra)
      expect(app_1).to_not equal app_2
    end
  end

  context "when the multiple-application configuration is used" do
    include Kookaburra::TestHelpers

    before(:all) do
      Kookaburra.forget_configuration!
      Kookaburra.configure do |c|
        c.application(:wilbur) do |a|
          a.api_driver_class = Kookaburra::APIDriver
          a.ui_driver_class = Kookaburra::UIDriver
        end
      end
    end

    specify "the app-specific accessors are no longer available after #forget_configuration! is called" do
      expect { wilbur }.not_to raise_error, "If this fails, something else is also failing; check that first"

      Kookaburra.forget_configuration!

      # But this shouldn't:
      expect { wilbur }.to raise_error(NameError), "Modules Are Forever. (From Ruby, With Love)"
    end
  end
end
