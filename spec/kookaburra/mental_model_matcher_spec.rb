require 'kookaburra/mental_model'

describe Kookaburra::MentalModel::Matcher do
  let(:mm) { Kookaburra::MentalModel.new }

  def matcher_for(collection_key)
    Kookaburra::MentalModel::Matcher.new(mm, collection_key).tap do |m|
      m.matches?(target)
    end
  end

  def self.pp_array(array)
    array = array.sort if array.all? { |e| e.respond_to?(:<=>) }
    array.inspect
  end
  def pp_array(array)
    self.class.pp_array(array)
  end

  let(:matcher) { matcher_for(:widgets) }

  def self.foo; { :name => 'Foo' } ; end
  def self.bar; { :name => 'Bar' } ; end
  def self.yak; { :name => 'Yak' } ; end
  let(:foo) { self.class.foo }
  let(:bar) { self.class.bar }
  let(:yak) { self.class.yak }

  def self.it_matches
    it "matches" do
      matcher.matches?(target).should be_true
    end
  end

  def self.it_doesnt_match
    it "doesn't match" do
      matcher.matches?(target).should be_false
    end
  end

  def self.it_complains_about_missing(missing, options)
    expected = options[:from]
    it "complains about missing elements" do
      msg = matcher.failure_message_for_should
      msg.should include("expected widgets to match the user's mental model, but:"), "bad preface"
      msg.should include("expected to be present:         #{pp_array(expected)}"),   "bad expected"
      msg.should include("the missing elements were:      #{pp_array(missing)}"),    "bad missing"
    end
  end

  def self.it_complains_about_extra(extra, options)
    unexpected = options[:in]
    it "complains about missing elements" do
      msg = matcher.failure_message_for_should
      msg.should include("expected widgets to match the user's mental model, but:"), "bad preface"
      msg.should include("expected to not be present:     #{pp_array(unexpected)}"), "bad unexepected"
      msg.should include("the unexpected extra elements:  #{pp_array(extra)}"),      "bad extra"
    end
  end

  context "expecting [];" do
    context "for [] (OK)" do
      let(:target) { [] }
      it_matches
    end

    context "for [foo] (foo not in mental model)" do
      let(:target) { [foo] }
      it_matches
    end
  end

  context "expecting [foo];" do
    before(:each) do
      mm.widgets[:foo] = foo
    end

    context "for [] (foo missing)" do
      let(:target) { [] }
      it_doesnt_match
      it_complains_about_missing [foo], :from => [foo]
    end

    context "for [foo] (OK: exact match)" do
      let(:target) { [foo] }
      it_matches
    end

    context "for [foo, bar] (OK: bar not in mental model)" do
      let(:target) { [foo, bar] }
      it_matches
    end
  end

  context "expecting [foo, bar];" do
    before(:each) do
      mm.widgets[:foo] = foo
      mm.widgets[:bar] = bar
    end

    context "for []" do
      let(:target) { [] }
      it_doesnt_match
      it_complains_about_missing [foo, bar], :from => [foo, bar]
    end

    context "for [foo] (bar missing)" do
      let(:target) { [foo] }
      it_doesnt_match
      it_complains_about_missing [bar], :from => [foo, bar]
    end

    context "for [foo, bar] (OK: exact match)" do
      let(:target) { [foo, bar] }
      it_matches
    end

    context "for [foo, bar, yak] (OK: foo, bar expected; yak not in mental model)" do
      let(:target) { [foo, bar, yak] }
      it_matches
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
      it_doesnt_match
      it_complains_about_missing [foo], :from => [foo]
    end

    context "for [bar] (foo missing, bar deleted)" do
      let(:target) { [bar] }
      it_doesnt_match
      it_complains_about_missing [foo], :from => [foo]
      it_complains_about_extra [bar], :in => [bar]
    end

    context "for [foo, bar] (bar deleted)" do
      let(:target) { [foo, bar] }
      it_doesnt_match
      it_complains_about_extra [bar], :in => [bar]
    end

    context "for [foo] (OK: foo expected, bar not found)" do
      let(:target) { [foo] }
      it_matches
    end

    context "for [foo, yak] (OK: foo expected; yak not in mental model)" do
      let(:target) { [foo, yak] }
      it_matches
    end
  end
end
