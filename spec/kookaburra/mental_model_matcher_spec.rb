require 'kookaburra/mental_model_matcher'

# Makes the specs themselves a bit less verbose. You should probably read the
# specs first, though.
module MentalModelMatcherMacros
  def self.included(receiver)
    receiver.extend ClassMethods
  end

  module ClassMethods
    def pp_array(array)
      array = array.sort if array.all? { |e| e.respond_to?(:<=>) }
      array.inspect
    end

    def it_matches
      it "matches" do
        matcher.matches?(target).should be_true
      end
    end

    def it_doesnt_match
      it "doesn't match" do
        matcher.matches?(target).should be_false
      end
    end

    def from_line
      #puts '#' * 80
      #puts "it is: '#{caller(2).first.split(':').inspect}'"
      #puts '#' * 81
      '(line %d)' % caller(2).first.split(':')[1]
    end

    def it_complains_about_missing(missing, options)
      expected = options[:expected]
      it "complains about a mismatch #{from_line}" do
        failure_msg.should include("expected widgets to match the user's mental model, but:")
      end
      it "says what it expected to be present #{from_line}" do
        failure_msg.should include("expected to be present:         #{pp_array(expected)}")
      end
      it "complains about missing items #{from_line}" do
        failure_msg.should include("the missing elements were:      #{pp_array(missing)}")
      end
    end

    def it_complains_about_extra(extra, options)
      unexpected = options[:unexpected]
      it "complains about a mismatch #{from_line}" do
        failure_msg.should include("expected widgets to match the user's mental model, but:")
      end
      it "says what it expected not to find #{from_line}" do
        failure_msg.should include("expected to not be present:     #{pp_array(unexpected)}")
      end
      it "complains about extra items #{from_line}" do
        failure_msg.should include("the unexpected extra elements:  #{pp_array(extra)}")
      end
    end
  end

  def matcher_for(collection_key)
    Kookaburra::MentalModel::Matcher.new(mm, collection_key).tap do |m|
      m.matches?(target)
    end
  end

  def pp_array(array)
    self.class.pp_array(array)
  end
end

describe Kookaburra::MentalModel::Matcher do
  include MentalModelMatcherMacros

  let(:mm) { Kookaburra::MentalModel.new }
  let(:matcher) { matcher_for(:widgets) }
  let(:failure_msg) { matcher.failure_message_for_should }

  def self.foo; 'FOO' ; end
  def self.bar; 'BAR' ; end
  def self.yak; 'YAK' ; end
  let(:foo) { self.class.foo }
  let(:bar) { self.class.bar }
  let(:yak) { self.class.yak }

  context "when mental model is [foo];" do
    before(:each) do
      mm.widgets[:foo] = foo
    end

    context "for [] (foo missing)" do
      let(:target) { [] }
      it_doesnt_match
      it_complains_about_missing [foo], :expected => [foo]
    end

    context "for [foo] (OK: exact match)" do
      let(:target) { [foo] }
      it_matches
    end

    context "for [foo, bar] (OK: bar ignored)" do
      let(:target) { [foo, bar] }
      it_matches
    end
  end

  context "when mental model is [];" do
    context "for [] (OK)" do
      let(:target) { [] }
      it_matches
    end

    context "for [foo] (OK: foo ignored)" do
      let(:target) { [foo] }
      it_matches
    end
  end

  context "when mental model is [foo, bar];" do
    before(:each) do
      mm.widgets[:foo] = foo
      mm.widgets[:bar] = bar
    end

    context "for [] (foo, bar missing)" do
      let(:target) { [] }
      it_doesnt_match
      it_complains_about_missing [foo, bar], :expected => [foo, bar]
    end

    context "for [foo] (bar missing)" do
      let(:target) { [foo] }
      it_doesnt_match
      it_complains_about_missing [bar], :expected => [foo, bar]
    end

    context "for [foo, bar] (OK: exact match)" do
      let(:target) { [foo, bar] }
      it_matches
    end

    context "for [foo, bar, yak] (OK: foo, bar expected; yak ignored)" do
      let(:target) { [foo, bar, yak] }
      it_matches
    end
  end

  context "when mental model is [foo], not expecting [bar];" do
    before(:each) do
      mm.widgets[:foo] = foo
      mm.widgets[:bar] = bar
      mm.widgets.delete(:bar)
    end

    context "for [] (foo missing)" do
      let(:target) { [] }
      it_doesnt_match
      it_complains_about_missing [foo], :expected => [foo]
    end

    context "for [bar] (foo missing, bar deleted)" do
      let(:target) { [bar] }
      it_doesnt_match
      it_complains_about_missing [foo], :expected => [foo]
      it_complains_about_extra [bar], :unexpected => [bar]
    end

    context "for [foo, bar] (bar deleted)" do
      let(:target) { [foo, bar] }
      it_doesnt_match
      it_complains_about_extra [bar], :unexpected => [bar]
    end

    context "for [foo] (OK: foo expected, bar not found)" do
      let(:target) { [foo] }
      it_matches
    end

    context "for [foo, yak] (OK: foo expected; yak ignored)" do
      let(:target) { [foo, yak] }
      it_matches
    end
  end

  describe "postfix scoping methods" do
    context "when mental model is [foo, bar];" do
      before(:each) do
        mm.widgets[:foo] = foo
        mm.widgets[:bar] = bar
      end

      context "but scoped to .only(:foo)" do
        let(:matcher) { matcher_for(:widgets).only(:foo) }

        context "for [foo] (OK)" do
          let(:target) { [foo] }
          it_matches
        end

        context "for [foo, bar] (not expecting [bar])" do
          let(:target) { [foo, bar] }
          it_doesnt_match
          it_complains_about_extra [bar], :unexpected => [bar]
        end
      end
    end

    context "when mental model is [foo];" do
      before(:each) do
        mm.widgets[:foo] = foo
      end

      context "but scoped with .expecting_nothing" do
        let(:matcher) { matcher_for(:widgets).expecting_nothing }

        context "for [] (OK)" do
          let(:target) { [] }
          it_matches
        end

        context "for [foo] (unexpected foo)" do
          let(:target) { [foo] }
          it_doesnt_match
          it_complains_about_extra [foo], :unexpected => [foo]
        end

        context "for [foo, bar] (unexpected [foo]; bar ignored)" do
          let(:target) { [foo, bar] }
          it_doesnt_match
          it_complains_about_extra [foo], :unexpected => [foo]
        end
      end
    end
  end
end
