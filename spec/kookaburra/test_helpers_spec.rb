require 'kookaburra/test_helpers'

describe Kookaburra::TestHelpers do
  include Kookaburra::TestHelpers

  before(:all) do
    Kookaburra.configure do |c|
      c.given_driver_class = Kookaburra::GivenDriver
      c.ui_driver_class    = Kookaburra::UIDriver
    end
  end

  after(:all) do
    Kookaburra.configure do |c|
      c.given_driver_class = nil
      c.ui_driver_class    = nil
    end
  end

  describe "#k" do
    it "returns an instance of Kookaburra" do
      k.should be_kind_of(Kookaburra)
    end

    it "memoizes" do
      a = k; b = k
      a.should equal(b)
    end
  end

  describe "methods delegated to #k" do
    it "includes #given" do
      k.should_receive(:given)
      given
    end

    it "includes #ui" do
      k.should_receive(:ui)
      ui
    end
  end

  describe "methods related to the mental model" do
    before(:each) do
      mm = k.send(:__mental_model__)
      mm.widgets[:foo] = 'FOO'
      mm.widgets[:bar] = 'BAR'
    end

    describe "#match_mental_model_of" do
      it "does a positive match" do
        ['FOO', 'BAR'].should match_mental_model_of(:widgets)
      end

      it "does a negative match" do
        ['BAZ'].should_not match_mental_model_of(:widgets)
      end

      it "works with scoping and mapping methods" do
        ['foo'].should match_mental_model_of(:widgets).mapped_by { |v|
          v.downcase
        }.where { |v|
          v != 'bar'
        }
      end
    end

    describe "#assert_mental_model_matches" do
      it "does a positive assertion" do
        actual = ['FOO', 'BAR']
        actual.should match_mental_model_of(:widgets) # Sanity check
        self.should_receive(:assert).never
        self.assert_mental_model_matches(:widgets, actual)
      end

      it "works with scoping and mapping methods" do
        mapper = Proc.new { |v| v.downcase }
        filter = Proc.new { |v| v != 'bar' }
        actual = ['foo']
        actual.should match_mental_model_of(:widgets).
          mapped_by(&mapper).
          where(&filter) # Sanity check
        self.should_receive(:assert).never
        self.assert_mental_model_matches(:widgets, actual, nil,
          :mapped_by => mapper,
          :where => filter)
      end

      it "does a negative assertion" do
        actual = ['BAZ']
        self.should_receive(:assert).with(false, kind_of(String))
        self.assert_mental_model_matches(:widgets, actual)
      end

      it "does a negative assertion with a custom message" do
        actual = ['YAK']
        psa = 'Put the razor down and step away!'
        self.should_receive(:assert).with(false, psa)
        self.assert_mental_model_matches(:widgets, actual, psa)
      end
    end
  end
end
