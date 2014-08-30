require 'spec_helper'
require 'kookaburra/test_helpers'

describe Kookaburra::TestHelpers do
  include Kookaburra::TestHelpers

  before(:all) do
    Kookaburra.configure do |c|
      c.api_driver_class = Kookaburra::APIDriver
      c.ui_driver_class    = Kookaburra::UIDriver
    end
  end

  after(:all) do
    Kookaburra.configure do |c|
      c.api_driver_class = nil
      c.ui_driver_class    = nil
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
