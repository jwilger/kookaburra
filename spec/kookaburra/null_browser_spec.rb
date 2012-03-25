require 'kookaburra/null_browser'

describe Kookaburra::NullBrowser do
  it 'is a BasicObject' do
    pending "Not sure how to test this, since a BasicObject doesn't implement #kind_of?, etc." do
      subject.kind_of?(BasicObject).should == true
    end
  end

  it 'raises a NullBrowserError when any methods are called on it' do
    lambda { subject.app }.should raise_error(
      Kookaburra::NullBrowserError,
      "You did not provide a :browser to the Kookaburra configuration, but you tried to use one anyway.")
  end
end
