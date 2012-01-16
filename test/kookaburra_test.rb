require 'helper'

describe Kookaburra do
  describe 'as a mixin' do
    let(:mixer_class) do
      Class.new do
        include Kookaburra
      end
    end

    let(:mixer) do
      mixer_class.new.tap do |m|
        m.kookaburra_adapter = adapter
      end
    end

    let(:mixer2) do
      mixer_class.new.tap do |m|
        m.kookaburra_adapter = adapter
      end
    end

    let(:adapter) do
      capybara_like_thing = Class.new do
        def app
          :an_application
        end

        def current_session
          :a_current_session
        end
      end

      capybara_like_thing.new
    end

    describe '#kookaburra_adapter' do
      it 'is a read/write attribute' do
        mixer = mixer_class.new
        assert_nil mixer.kookaburra_adapter
        mixer.kookaburra_adapter = :probably_Capybara
        assert_equal :probably_Capybara, mixer.kookaburra_adapter
      end
    end

    describe '#api' do
      it 'is an instance of Kookaburra::APIDriver' do
        assert_kind_of(Kookaburra::APIDriver, mixer.api)
      end

      it 'only creates a new one once for an instance of the including class' do
        assert_same(mixer.api, mixer.api)
      end

      it 'is a different instance of APIDriver for each instance of the including class' do
        refute_same mixer.api, mixer2.api
      end
    end

    describe '#given' do
      it 'is an instance of Kookaburra::GivenDriver' do
        assert_kind_of(Kookaburra::GivenDriver, mixer.given)
      end

      it 'only creates a new one once for an instance of the including class' do
        assert_same(mixer.given, mixer.given)
      end

      it 'is a different instance of GivenDriver for each instance of the including class' do
        refute_same mixer.given, mixer2.given
      end
    end

    describe '#ui' do
      it 'is an instance of Kookaburra::UIDriver' do
        assert_kind_of(Kookaburra::UIDriver, mixer.ui)
      end

      it 'only creates a new one once for an instance of the including class' do
        assert_same(mixer.ui, mixer.ui)
      end

      it 'is a different instance of UIDriver for each instance of the including class' do
        refute_same mixer.ui, mixer2.ui
      end
    end
  end
end
