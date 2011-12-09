# This is the mechanism for sharing state between Cucumber steps.
# If you're using instance variables, YOU'RE DOING IT WRONG.
class Kookaburra::TestData
  def initialize
    @data = Hash.new do |hash, key|
      hash[key] = Hash.new { |hash, key| hash[key] = HashWithIndifferentAccess.new }
    end
  end

  def __collection(collection_key)
    @data[collection_key]
  end
  def __fetch_data(collection_key, value_key)
    __collection(collection_key).fetch(value_key)
  rescue IndexError => e
    raise e.exception("Key #{value_key.inspect} not found in #{collection_key}")
  end
  def __get_data(collection_key, value_key)
    __collection(collection_key)[value_key]
  end
  def __set_data(collection_key, value_key, value_hash = {})
    __collection(collection_key)[value_key] = HashWithIndifferentAccess.new(value_hash)
  end

  def self.provide_collection(name)
    class_eval <<-RUBY
      def #{name}(key = :default)
        __get_data(:#{name}, key)
      end
      def fetch_#{name}(key = :default)
        __fetch_data(:#{name}, key)
      end
      def set_#{name}(key, value_hash = {})
        __set_data(:#{name}, key, value_hash)
      end
    RUBY
  end

  provide_collection :user
  provide_collection :financing_application
  provide_collection :instance

  Defaults = HashWithIndifferentAccess.new
  Defaults[:instance] = HashWithIndifferentAccess.new
  Defaults[:contact_info] = HashWithIndifferentAccess.new({
    :contact_name           => 'Boulevard Cinemas',
    :contact_email          => 'info@cinemawest.example.com',
    :contact_street_address => '200 C Street',
    :contact_city           => 'Petaluma',
    :contact_state          => 'CA',
    :contact_zipcode        => '94952',
    :contact_phone          => '(707) 762-7469',
  })
  Defaults[:financing_application_eligibility] = HashWithIndifferentAccess.new({
    :property_address           => '200 C Street',
    :property_type_nickname     => 'single_family',
  })
  Defaults[:property_info] = HashWithIndifferentAccess.new({
    :parcel_number              => '1234567',
    :property_heating_type      => 'electric',
    :property_cooling_type      => 'none',
    :test_in_type               => 'hers_II',
    :test_in_energy_assessment  => 'true',
  })
  Defaults[:owner_info] = HashWithIndifferentAccess.new({
    :owner_name => 'Joe Schmoe Co.',
    :owner_type => 'organization',
    :ssn => '6789',
    :daytime_phone => '(503) 555-1234',
    :evening_phone => '(503) 333-1234',
  })
  Defaults[:payment_request] = HashWithIndifferentAccess.new({
    :name => 'title',
    :description => 'This is the fee you pay to do stuff to your own house!',
    :amount_cents => 1500,
    :required => false
  })
  Defaults[:financing_application_with_one_improvement] = HashWithIndifferentAccess.new({
    :last_completed_step => 'add_improvements',
    :improvements_attributes => [
      { :quantity => '2',
        :expected_consumption_savings => '1000',
        :proposed_specifications => "Specs go here",
        :proposed_make_and_model => "The Newest thing",
        :measure => "Aerators, Faucet",
        :expected_cost => "32000",
        :expected_rebates => "1000",
        :expected_permit_fee => "200"
      }
    ]
  })

  Defaults[:financing_application_financing_summary_inputs] = HashWithIndifferentAccess.new({
    :expected_other_costs => "1000.00",
    :expected_money_down => "750.00",
    :contingency => "No",
    :payment_terms => "10"
  })

  Defaults[:financing_application_financing_summary_calculated] = HashWithIndifferentAccess.new({
    :contingency_amount => "3120.00",
    :requested_financing_amount => "31450.00",
    :estimated_yearly_payment  => "4381.93"
  })

  Defaults[:credit_card_info] = HashWithIndifferentAccess.new({
    :credit_card_first_name => 'Bob',
    :credit_card_last_name => 'Sled',
    :credit_card_number => '1',
    :credit_card_month => '12',
    :credit_card_year => (Date.today.year + 1).to_s,
    :credit_card_verification_value => '100'
  })

  def default(key)
    # NOTE: Marshal seems clunky, but gives us a deep copy.
    # This keeps mutations from being preserved between test runs.
    ( @default ||= Marshal::load(Marshal.dump(Defaults)) )[key]
  end

  def factory
    @factory ||= Kookaburra::TestData::Factory.new(self)
  end
end
