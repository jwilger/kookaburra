require 'kookaburra/mental_model'

describe Kookaburra::MentalModel::Matcher do
  let(:mm) { Kookaburra::MentalModel.new }

  def matcher_for(collection_key)
    Kookaburra::MentalModel::Matcher.new(mm, collection_key)
  end
  
  let(:matcher) { matcher_for(:widgets).tap { |m| m.matches?(target) } }

  let(:foo) { { :name => 'Foo', :type => 'widget' } }
  let(:bar) { { :name => 'Bar', :type => 'widget' } }
  let(:yak) { { :name => 'Yak', :type => 'widget' } }

  context "when the named collection has nothing in it" do
    context "and the actual list is an empty array" do
      let(:target) { [] }

      it "#matches? returns true when given an empty array" do
        matcher.matches?(target).should be_true
      end
    end

    context "and the actual list is [foo] (foo not in mental model)" do
      let(:target) { [foo] }
      it "#matches? returns true" do
        matcher.matches?(target).should be_true
      end
    end
  end

  context "when the named collection has foo in it" do
    before(:each) do
      mm.widgets[:foo] = foo
    end

    context "and the actual list is an empty array (foo missing)" do
      let(:target) { [] }

      it '#matches? returns false' do
        matcher.matches?(target).should be_false
      end

      it "#failure_message_for_should complains about missing element" do
        matcher.failure_message_for_should.should == <<-EOF
expected widgets to match the user's mental model, but:
expected to be present:         #{[foo].inspect}
the missing elements were:      #{[foo].inspect}
EOF
      end
    end

    context "and the actual list is [foo] (OK)" do
      let(:target) { [foo] }

      it "#matches? returns true" do
        matcher.matches?(target).should be_true
      end
    end

    context "and the actual list is [foo, bar] (bar not in mental model)" do
      let(:target) { [foo, bar] }

      it "#matches? returns true" do
        matcher.matches?(target).should be_true
      end
    end
  end

  context "when the named collection has foo in it, and deleted bar" do
    before(:each) do
      mm.widgets[:foo] = foo
      mm.widgets[:bar] = bar
      mm.widgets.delete(:bar)
    end

    context "when the actual list is an empty array (foo missing)" do
      let(:target) { [] }
      
      it "#matches? returns false" do
        matcher.matches?(target).should be_false
      end

      it '#failure_message_for_should'
    end

    context "when the actual list is [bar] (foo missing, bar deleted)" do
      let(:target) { [bar] }
      
      it "#matches? returns false" do
        matcher.matches?(target).should be_false
      end

      it '#failure_message_for_should'
    end

    context "when the actual list is [foo, bar] (bar deleted)" do
      let(:target) { [foo, bar] }
      
      it "#matches? returns false" do
        matcher.matches?(target).should be_false
      end

      it '#failure_message_for_should'
    end

    context "when the actual list is [foo] (foo expected)" do
      let(:target) { [foo] }
      
      it "#matches? returns true" do
        matcher.matches?(target).should be_true
      end
    end

    context "when the actual list is [foo, yak] (foo expected; yak not in mental model)" do
      let(:target) { [foo, yak] }
      
      it "#matches? returns true" do
        matcher.matches?(target).should be_true
      end
    end
  end

  describe "chaining methods for scoping" do
    it "should have them"
  end
end
