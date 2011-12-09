module Kookaburra
  class APIDriver
    include Plumbing
    include JSONTools

    # Pattern:
    # - Get some data from test_data.factory
    # - Post it to the API
    # - Remember the response in test_data

    def create_user(attrs = {})
      user_attrs = test_data.factory.new_user
      post_as_json 'User', users_path, :user => user_attrs
      test_data.set_user :default, hash_from_response_json[:user].reverse_merge(:password => user_attrs[:password])
    end

    def create_financing_application(attrs = {})
      fin_app_attrs = test_data.factory.eligible_app(attrs)
      post_as_json 'Financing application', fin_apps_path, user_and(fin_app_attrs)
      remember_fin_app_response
    end

    def set_one_owner(attrs = {})
      update_fin_app 'Adding one owner', test_data.factory.fin_app_with_one_owner(attrs)
    end

    def set_two_owners(attrs = {})
      update_fin_app 'Adding two owners', test_data.factory.fin_app_with_two_owners(attrs)
    end

    def update_property_details(attrs = {})
      update_fin_app 'Property details', test_data.factory.fin_app_with_property_and_contact_info(attrs)
    end

    def update_financing_summary(attrs = {})
      update_fin_app 'Financing summary', test_data.factory.fin_app_with_financing_summary(attrs)
    end

    def create_one_improvement(attrs = {})
      update_fin_app 'Improvement', test_data.factory.fin_app_with_one_improvement(attrs)
    end

    def financing_application
      self #hack hack hack
    end

    def has_completed_appian_intake?
      fin_app_status[:appian_intake_completed]
    end

    def accept_terms_and_mock_appian_intake(attrs = {})
      update_fin_app 'Terms', test_data.factory.fin_app_with_terms_and_fake_appian_intake(attrs)
    end

    def mock_appian_request_fee_payments(attrs = {})
      update_fin_app 'Payment Requests', test_data.factory.fin_app_with_two_payment_requests(attrs)
    end

    protected
    def users_path
      '/api/v1/users'
    end

    def fin_apps_path
      '/api/v1/financing_applications'
    end

    def current_fin_app_path
      '/api/v1/financing_applications/%d' % test_data.fetch_financing_application[:id]
    end

    def update_fin_app(short_description, fin_app_attrs)
      put_as_json short_description, current_fin_app_path, user_and(fin_app_attrs)
      remember_fin_app_response
    end

    def fin_app_status
      url = '/api/v1/financing_applications/%d/status.json' % test_data.fetch_financing_application[:id]
      response = get(url, :user => current_user_for_auth)
      h = HashWithIndifferentAccess.new(JSON.parse(response.body))
    end

    def remember_fin_app_response
      test_data.set_financing_application :default, hash_from_response_json[:financing_application]
      return test_data.financing_application   # for when this is used in appian_submitter_spec.rb
    end

    def user_and(fin_app_data)
      {
        :user     => current_user_for_auth,
        :app_data => fin_app_data,
      }
    end

    def current_user_for_auth
      begin
        user = test_data.fetch_user
      rescue IndexError => e
        create_user
        user = test_data.fetch_user
      end
      user.slice(:email, :password)
    end
  end
end
