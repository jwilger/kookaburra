require 'kookaburra/configuration'
require 'support/shared_examples/it_has_a_dependency_accessor'

describe Kookaburra::Configuration do
  it_behaves_like :it_has_a_dependency_accessor, :given_driver_class
  it_behaves_like :it_has_a_dependency_accessor, :ui_driver_class
  it_behaves_like :it_has_a_dependency_accessor, :browser
  it_behaves_like :it_has_a_dependency_accessor, :app_host
  it_behaves_like :it_has_a_dependency_accessor, :mental_model

  describe '#server_error_detection' do
    it 'returns the block that it was last given' do
      block = lambda { 'foo' }
      subject.server_error_detection(&block)
      subject.server_error_detection.should == block
    end
  end
end
