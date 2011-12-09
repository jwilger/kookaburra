# Factories for setting up attribute hashes
class Kookaburra::TestData::Factory
  attr_reader :test_data
  def initialize(test_data)
    @test_data = test_data
  end

  def new_user(overrides = {})
    uuid = `uuidgen`.strip
    overrides.reverse_merge({
      :name     => "Test User #{uuid}",
      :email    => "test-user-#{uuid}@example.com",
      :password => 'password',
    })
  end

  def eligible_app(overrides = {})
    fin_app_data(overrides) do |app_data|
      app_data.reverse_merge! test_data.default(:financing_application_eligibility)
      app_data.merge! :last_completed_step => 'eligibility'
    end
  end

  def fin_app_with_one_owner(overrides = {})
    fin_app_data(overrides) do |app_data|
      app_data.reverse_merge! :property_owners => [test_data.default(:owner_info)]
      app_data.merge! :last_completed_step => 'eligibility'
    end
  end

  def fin_app_with_two_owners(overrides = {})
    fin_app_data(overrides) do |app_data|
      app_data.reverse_merge! :property_owners => [test_data.default(:owner_info)] * 2
      app_data.merge! :last_completed_step => 'eligibility'
    end
  end

  def fin_app_with_property_and_contact_info(overrides = {})
    fin_app_data(overrides) do |app_data|
      app_data.merge! test_data.default(:property_info)
      app_data.merge! test_data.default(:contact_info)
      app_data.merge! :last_completed_step => 'property_details'
    end
  end

  def fin_app_with_terms_and_fake_appian_intake(overrides = {})
    fin_app_data(overrides) do |app_data|
      app_data.merge! :terms_accepted_at => DateTime.now
      app_data.merge! :last_completed_step => 'accept_terms'
      app_data.merge! :appian_application_id => 1
      app_data.merge! :appian_intake_process_id => 1
    end
  end

  def fin_app_with_two_payment_requests(overrides = {})
    fin_app_data(overrides) do |app_data|
      app_data.reverse_merge! :payment_requests => [
        test_data.default(:payment_request).merge(:nickname => 'one', :required => true),
        test_data.default(:payment_request).merge(:name => 'recording', :nickname => 'two')
      ]
    end
  end

  def fin_app_with_financing_summary(overrides = {})
    fin_app_data(overrides) do |app_data|
      app_data.reverse_merge! test_data.default(:financing_application_financing_summary_inputs)
      app_data.merge! :last_completed_step => 'financing_summary'
    end
  end

  def fin_app_with_one_improvement(overrides = {})
    fin_app_data(overrides) do |app_data|
      app_data.reverse_merge! test_data.default(:financing_application_with_one_improvement)
    end
  end


  protected
  def fin_app_data(overrides = {})
    overrides.dup.tap do |app_data|
      yield app_data if block_given?
    end
  end
end
