class Kookaburra::UIDriver
  include HasBrowser
  include HasUIComponent

  attr_reader :test_data

  def initialize(opts = {})
    super
    @test_data = opts.fetch(:test_data)
  end

  ui_component :login_form
  ui_component :eligibility_form
  ui_component :property_details_form
  ui_component :payment_form
  ui_component :improvements_form
  ui_component :financing_summary_form
  ui_component :terms_and_conditions_form

  def log_out
    visit '/users/sign_out'
  end

  # If we're not testing login, submit as efficiently as possible,
  # and short circuit the full form interaction.
  def be_logged_in(user_key = :default)
    user = user_hash(user_key)
    login_form.log_in_fast_as user
  end

  def log_in(user_key = :default)
    # Capybara resets sessions after every feature (
    # Capybara.reset_sessions!), so there is no need to
    # explicitly log out or clear cookies here. If we
    # we ever have a feature with multiple log-ins, we
    # should use separate sessions for those.
    user = user_hash(user_key)
    login_form.log_in_as user
  end

  def has_validation_errors?
    browser.has_css?('.required.error')
  end

  def validation_errors
    browser.all(:css, '.required.error').map(&:text).join("\n")
  end

  def save_changes
    current_component.submit!
  end

  protected
  def user_hash(user_key)
    if user_key.kind_of?(Hash)
      user_key
    else
      test_data.fetch_user(user_key)
    end
  end
end
