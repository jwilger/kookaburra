require 'spec_helper'

describe Kookaburra::Configuration::Proxy do
  subject { described_class.new(name: :foobar, basis: basis) }

  let(:basis) {
    Kookaburra::Configuration.new.tap do |c|
      c.ui_driver_class = default_ui_driver_class
    end
  }

  let(:default_ui_driver_class) { double(:default_ui_driver_class) }

  it 'it knows the name with which it was created' do
    expect(subject.name).to eq :foobar
  end

  it 'delegates to its basis by default' do
    expect(subject.ui_driver_class).to equal default_ui_driver_class
  end

  it 'does not delegate attributes that are set explicitly to a value' do
    ui_driver_class_override = double(:ui_driver_class_override)
    subject.ui_driver_class = ui_driver_class_override
    expect(basis.ui_driver_class).to equal default_ui_driver_class
    expect(subject.ui_driver_class).to equal ui_driver_class_override
  end

  it 'does not delegate attributes that are set explicitly to nil' do
    subject.ui_driver_class = nil
    expect(basis.ui_driver_class).to equal default_ui_driver_class
    expect(subject.ui_driver_class).to be_nil
  end

  it 'responds only to methods to which its basis also responds' do
    expect{ subject.not_a_defined_method }.to raise_error(NameError)
    expect{ subject.not_a_defined_method = :something }.to raise_error(NameError)
  end
end
