class Kookaburra::GivenDriver
  def initialize(opts)
    @api = opts.fetch(:api_driver)
  end

  def a_user
    @api.create_user
  end

  def valid_financing_application
    @api.create_financing_application
    @api.update_property_details
  end

  def financing_application_for_appian_intake
    valid_financing_application
    @api.set_two_owners
    @api.create_one_improvement
    @api.update_financing_summary
  end

  def financing_application_for_payment
    @api.create_financing_application
    @api.update_property_details
    @api.set_two_owners
    @api.update_financing_summary
    @api.create_one_improvement
    @api.accept_terms_and_mock_appian_intake
    @api.mock_appian_request_fee_payments
  end

  def financing_application_ready_to_accept_terms
    valid_financing_application
    @api.set_one_owner
    @api.update_financing_summary
    @api.create_one_improvement
  end
end
