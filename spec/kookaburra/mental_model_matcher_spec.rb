require 'kookaburra/mental_model'

describe Kookaburra::MentalModel::Matcher do
  let(:mm) { Kookaburra::MentalModel.new }

  def matcher_for(collection_key)
    Kookaburra::MentalModel::Matcher.new(mm, collection_key).tap do |m|
      m.matches?(target)
    end
  end

  def pp_array(array)
    array = array.sort if array.all? { |e| e.respond_to?(:<=>) }
    array.inspect
  end

  let(:matcher) { matcher_for(:widgets) }

  let(:foo) { { :name => 'Foo', :type => 'widget' } }
  let(:bar) { { :name => 'Bar', :type => 'widget' } }
  let(:yak) { { :name => 'Yak', :type => 'widget' } }

  def self.it_matches
    it "matches (short form)" do
      matcher.matches?(target).should be_true
    end
  end

  context "expecting [];" do
    context "for []" do
      let(:target) { [] }

      it "matches when given an empty array" do
        matcher.matches?(target).should be_true
      end
    end

    context "for [foo] (foo not in mental model)" do
      let(:target) { [foo] }

      it "matches" do
        matcher.matches?(target).should be_true
      end
    end
  end

  context "expecting [foo];" do
    before(:each) do
      mm.widgets[:foo] = foo
    end

    context "for [] (foo missing)" do
      let(:target) { [] }

      it 'does not match' do
        matcher.matches?(target).should be_false
      end

      it "complains about missing foo" do
        matcher.failure_message_for_should.should == <<-EOF
expected widgets to match the user's mental model, but:
expected to be present:         #{pp_array([foo])}
the missing elements were:      #{pp_array([foo])}
EOF
      end
    end

    context "for [foo] (OK)" do
      let(:target) { [foo] }

      it "matches" do
        matcher.matches?(target).should be_true
      end
    end

    context "for [foo, bar] (bar not in mental model)" do
      let(:target) { [foo, bar] }

      it "matches" do
        matcher.matches?(target).should be_true
      end
    end
  end

  context "expecting [foo, bar];" do
    before(:each) do
      mm.widgets[:foo] = foo
      mm.widgets[:bar] = bar
    end

    context "for []" do
      let(:target) { [] }
      
      it "does not match" do
        matcher.matches?(target).should be_false
      end

      it 'complains about missing foo, bar' do
        matcher.failure_message_for_should.should == <<-EOF
expected widgets to match the user's mental model, but:
expected to be present:         #{pp_array([foo, bar])}
the missing elements were:      #{pp_array([foo, bar])}
EOF
      end
    end

    context "for [bar] (foo missing)" do
      let(:target) { [bar] }
      
      it "does not match" do
        matcher.matches?(target).should be_false
      end

      it 'complains about missing foo' do
        matcher.failure_message_for_should.should == <<-EOF
expected widgets to match the user's mental model, but:
expected to be present:         #{pp_array([foo, bar])}
the missing elements were:      #{pp_array([foo])}
EOF
      end
    end

    context "for [foo, bar] (OK)" do
      let(:target) { [foo, bar] }
      
      it "does not match" do
        matcher.matches?(target).should be_true
      end
    end

    context "for [foo, bar, yak] (foo, bar expected; yak not in mental model)" do
      let(:target) { [foo, bar, yak] }
      
      it "matches" do
        matcher.matches?(target).should be_true
      end
    end
  end

  context "expecting [foo], not expecting [bar];" do
    before(:each) do
      mm.widgets[:foo] = foo
      mm.widgets[:bar] = bar
      mm.widgets.delete(:bar)
    end

    context "for [] (foo missing)" do
      let(:target) { [] }
      
      it "does not match" do
        matcher.matches?(target).should be_false
      end

      it 'complains about missing foo' do
        matcher.failure_message_for_should.should == <<-EOF
expected widgets to match the user's mental model, but:
expected to be present:         #{pp_array([foo])}
the missing elements were:      #{pp_array([foo])}
EOF
      end
    end

    context "for [bar] (foo missing, bar deleted)" do
      let(:target) { [bar] }
      
      it "does not match" do
        matcher.matches?(target).should be_false
      end

      it 'complains about missing foo and extra bar' do
        matcher.failure_message_for_should.should == <<-EOF
expected widgets to match the user's mental model, but:
expected to be present:         #{pp_array([foo])}
the missing elements were:      #{pp_array([foo])}
expected to not be present:     #{pp_array([bar])}
the unexpected extra elements:  #{pp_array([bar])}
EOF
      end
    end

    context "for [foo, bar] (bar deleted)" do
      let(:target) { [foo, bar] }
      
      it "does not match" do
        matcher.matches?(target).should be_false
      end

      it 'complains about extra bar' do
        matcher.failure_message_for_should.should == <<-EOF
expected widgets to match the user's mental model, but:
expected to not be present:     #{pp_array([bar])}
the unexpected extra elements:  #{pp_array([bar])}
EOF
      end
    end

    context "for [foo] (foo expected)" do
      let(:target) { [foo] }
      
      it "matches" do
        matcher.matches?(target).should be_true
      end
    end

    context "for [foo, yak] (foo expected; yak not in mental model)" do
      let(:target) { [foo, yak] }
      
      it "matches" do
        matcher.matches?(target).should be_true
      end
    end
  end

  describe "chaining methods for scoping" do
    it "should have them"
  end
end
