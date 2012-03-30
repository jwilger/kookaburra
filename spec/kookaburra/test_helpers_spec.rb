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
    let(:mm) { Kookaburra.configuration.mental_model }

    describe "#match_mental_model_of" do
      def sanity_check
        match_mental_model_of(:widgets).should be_kind_of(Kookaburra::MentalModel::Matcher)
      end

      before(:each) do
        sanity_check
        mm.widgets[:foo] = 'FOO'
      end

      it "does a positive match" do
        ['FOO'].should match_mental_model_of(:widgets)
      end

      it "does a negative match" do
        ['BAR'].should_not match_mental_model_of(:widgets)
      end
    end

    describe "#assert_mental_model_of" do
      let(:test_case) {
        Object.new.tap do |obj|
          obj.extend Kookaburra::TestHelpers

          def obj.assert(predicate, message)
            predicate || message
          end
        end
      }

      before(:each) do
        mm.widgets[:foo] = 'FOO'
      end

      it "does a positive assertion" do
        result = test_case.assert_mental_model_of(:widgets, ['FOO'])
        result.should be_true
      end

      it "does a negative assertion" do
        result = test_case.assert_mental_model_of(:widgets, ['BAR'])
        result.should =~ /expected widgets to match the user's mental model, but/
      end

      it "does a negative assertion with a custom message" do
        psa = 'Put the razor down and step away!'
        result = test_case.assert_mental_model_of(:widgets, ['YAK'], psa)
        result.should == psa
      end
    end
  end
end
