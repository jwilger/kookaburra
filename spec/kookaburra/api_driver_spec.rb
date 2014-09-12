require 'spec_helper'

describe Kookaburra::APIDriver do
  subject {
    klass = Class.new(described_class) do
      def do_something
        api
      end
    end
    klass.new(configuration)
  }

  let(:configuration) { double(:configuration) }

  it 'requires subclasses to implement their #api method' do
    expect{ subject.do_something }.to raise_error(Kookaburra::ConfigurationError)
  end
end
