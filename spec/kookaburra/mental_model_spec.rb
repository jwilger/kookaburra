require 'spec_helper'
require 'kookaburra/mental_model'

describe Kookaburra::MentalModel do
  describe '#method_missing' do
    it 'returns a Collection' do
      expect(subject.foo).to be_kind_of(Kookaburra::MentalModel::Collection)
    end

    it 'returns different Collections for different messages' do
      expect(subject.foo).to_not equal subject.bar
    end
  end

  describe Kookaburra::MentalModel::Collection do
    let(:collection) { Kookaburra::MentalModel::Collection.new('widgets') }

    describe '#values_at' do
      it 'returns an array of items matching the specified keys' do
        collection[:foo] = 'foo'
        collection[:bar] = 'bar'
        collection[:baz] = 'baz'
        expect(collection.values_at(:foo, :baz)).to eq %w(foo baz)
      end
    end

    describe '#slice' do
      it 'returns a hash of items from the collection that match the specified keys' do
        collection[:foo] = 'foo'
        collection[:bar] = 'bar'
        collection[:baz] = 'baz'
        expect(collection.slice(:foo, :baz)).to eq({:foo => 'foo', :baz => 'baz'})
      end
    end

    describe '#except' do
      it 'returns a hash of items from the collection that do not match the specified keys' do
        collection[:foo] = 'foo'
        collection[:bar] = 'bar'
        collection[:baz] = 'baz'
        collection[:yak] = 'yak'
        expect(collection.except(:foo, :baz)).to eq({:bar => 'bar', :yak => 'yak'})
      end
    end

    describe '#delete' do
      it 'deletes and returns the item matching the specified key' do
        collection[:baz] = 'baz'
        expect(collection.delete(:baz)).to eq 'baz'
        expect{ collection[:baz] }.to raise_error(Kookaburra::UnknownKeyError)
      end

      it 'persists the deleted key/value pair to the #deleted subcollection' do
        collection[:baz] = 'baz'
        collection.delete(:baz)
        expect(collection.deleted[:baz]).to eq 'baz'
      end

      it 'raises a Kookaburra::UnknownKeyError exception if trying to delete a missing key' do
        expect{ collection.delete(:snerf) }.to \
          raise_error(Kookaburra::UnknownKeyError, "Can't find mental_model.widgets[:snerf]. Did you forget to set it?")
      end
    end

    describe '#delete_if' do
      before(:each) do
        collection[:foo] = 'foo'
        collection[:bar] = 'spoon'
        collection[:baz] = 'baz'
      end

      it 'deletes all members of collection for whom given block evaluates to false' do
        collection.delete_if { |k,v| k.to_s != v }
        expect(collection.keys).to match_array [:foo, :baz]
      end

      it 'adds deleted members of collection to #deleted subcollection' do
        collection.delete_if { |k,v| k.to_s != v }
        expect(collection.deleted.keys).to eq [:bar]
      end

      it 'returns hash of items not deleted' do
        expect(collection.delete_if { |k,v| k.to_s != v }).to \
          eq({:foo => 'foo', :baz => 'baz'})
      end
    end

    describe '#deleted' do
      it 'generates a new subcollection if none exists' do
        initialized_collection = collection
        expect(Kookaburra::MentalModel::Collection).to receive(:new) \
          .with("#{initialized_collection.name}.deleted")
        initialized_collection.deleted
      end

      it 'returns the deleted subcollection if already initialized' do
        deleted_collection = collection.deleted
        expect(collection.deleted).to equal deleted_collection
      end
    end

    it 'raises a Kookaburra::UnknownKeyError exception for #[] with a missing key' do
      expect{ collection[:foo] }.to \
        raise_error(Kookaburra::UnknownKeyError, "Can't find mental_model.widgets[:foo]. Did you forget to set it?")
    end

    describe '#dup' do
      it 'returns a different object' do
        new_collection = collection.dup
        expect(new_collection).to_not equal collection
      end

      it 'returns an object with equal values to the original' do
        collection[:foo] = :bar
        collection[:baz] = :bam
        new_collection = collection.dup
        expect(new_collection[:foo]).to eq :bar
        expect(new_collection[:baz]).to eq :bam
      end

      it 'is a deep copy' do
        collection[:foo] = {:bar => 'baz'}
        new_collection = collection.dup
        expect(new_collection[:foo][:bar]).to eq 'baz'
        expect(new_collection[:foo][:bar]).to_not equal collection[:foo][:bar]
      end

      context 'when there are deleted items present' do
        it 'also dupes the deleted items' do
          collection[:foo] = 'foo'
          collection[:bar] = 'bar'
          deleted = collection.delete(:bar)
          new_collection = collection.dup
          expect(new_collection.deleted[:bar]).to eq deleted
          expect(new_collection.deleted[:bar]).to_not equal deleted
        end
      end
    end
  end
end
