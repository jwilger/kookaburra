# Kookaburra #

Kookaburra is a framework for implementing the [Window Driver] [Window Driver] pattern in
order to keep acceptance tests maintainable.

## Installation ##

Kookaburra is available as a Rubygem and [published on Rubygems.org] [Kookaburra
Gem], so installation is trivial:

    gem install kookaburra

If you're using [Bundler](http://gembundler.com/) for your project, just add the
following:

    group :development, :test do
      gem 'kookaburra'
    end

## Setup ##

Kookaburra itself abstracts some common patterns for implementing the Window
Driver pattern for tests of Ruby web applications built on [Rack] [Rack]. You will need
to tell Kookaburra which classes contain the specific Domain Driver
implementations for your application as well as which driver to use for running
the tests (currently only tested with [Capybara] [Capybara]). The details of setting up your
Domain Driver layer are discussed below, but in general you will need the
following in a locations such as `lib/my_application/kookaburra.rb` (replace
`MyApplication` with a module name suitable to your actual application:

    module MyApplication
      module Kookaburra
        ::Kookaburra.adapter = Capybara

        # Note: the following assigned classes are defined under your
        # application's namespace, e.g. MyApplication::Kookaburra::APIDriver
        ::Kookaburra.api_driver = APIDriver
        ::Kookaburra.given_driver = GivenDriver
        ::Kookaburra.ui_driver = UIDriver

        ::Kookaburra.test_data_setup do
          provide_collection :accounts
          # See section on Test Data for more examples of what can go here.
        end
      end
    end

### RSpec ###

For [RSpec] [RSpec] integration tests, just add the following to
`spec/support/kookaburra_setup.rb`:

    require 'my_application/kookaburra'

    RSpec.configure do |c|
      c.include(Kookaburra, :type => :request)
    end

### Cucumber ###

For [Cucumber] [Cucumber], add the following to `features/support/kookaburra_setup.rb`:

    require 'my_application/kookaburra'

    Kookaburra.adapter = Capybara
    World(Kookaburra)

    Before do
      # Ensure that there isn't state-leakage between scenarios
      kookaburra_reset!
    end

This will cause the #api, #given and #ui methods will be available in your
Cucumber step definitions.

## Defining Your Testing DSL ##

Kookaburra attempts to extract some common patterns that make it easier to use
the Window Driver pattern along with various Ruby testing frameworks, but you
still need to define your own testing DSL. An acceptance testing stack using
Kookaburra has the following layers:

1. The **Business Specification Language** (Cucumber scenarios or other
   spcification documents)
2. The **Test Implementation** (Cucumber step definitions, RSpec example blocks,
   etc.)
3. The **Domain Driver** (Kookaburra::GivenDriver and Kookaburra::UIDriver)
4. The **Window Driver** (Kookaburra::UIDriver::UIComponent)
5. The **Application Driver** (Capybara and Rack::Test)

### The Business Specification Language ###

The business specification language consists of the highest-level descriptions
of a feature that are suitable for sharing with the non/less-technical
stakeholders on a project.

Gherkin is the external DSL used by Cucumber for this purpose, and you might
have the following scenario defined for an e-commerce application:

    # purchase_items_in_cart.feature

    Feature: Purchase Items in Cart

      Scenario: Using Existing Billing and Shipping Information
        
        Given I have an existing account
        And I have previously specified default payment options
        And I have previously specified default shipping options
        And I have an item in my shopping cart

        When I sign in to my account
        And I choose to check out

        Then I see my order summary
        And I see that my default payment options will be used
        And I see that my default shipping options will be used

Note that the scenario is focused on business concepts versus interface details,
i.e. you "choose to check out" rather than "click on the checkout button". If
for some reason your e-commerce system was going to be a terminal application
rather than a web application, you would not need to change this scenario at
all, because the actual business concepts described would not change.

### The Test Implementation ###

The Test Implementation layer exists as the line in between the Business
Specification Language and the Domain Driver, and it includes Cucumber step
definitions, RSpec example blocks, Test::Unit tests, etc. At this layer, your
code orchestrates calls into the Domain Driver to mimic user interactions under
various conditions and make assertions about the results.

**Assertions always belong within the test implementation layer.** Some testing
frameworks such as RSpec add methods like `#should` to `Object`, which has the
effect of poisoning the entire Ruby namespace with these methods---if you are
using RSpec, you can call `#should` anywhere in your code and it will work when
RSpec is loaded. Do not be tempted to call a testing library's Object decorators
anywhere outside of your test implementation (such as within `UIDriver` or
`UIComponent` subclasses.) Doing so will tightly couple your Domain Driver
and/or Window Driver implementation to a specific testing library. If you must
make some type of assertion within the Domain Driver layer, a better approach is
to simply raise an exception with an informative error message when some desired
condition is not met. Kookaburra provides its own `#assert` method; you may use
this directly or build your own custom assertions using it as a base.

Given the Cucumber scenario above, here is how the test implementation layer
might look:

    # step_definitions/various_steps.rb

    Given "I have an existing account" do
      given.existing_account(:my_account)
    end

    Given "I have previously specified default payment options" do
      given.default_payment_options_specified_for(:my_account)
    end

    Given "I have previously specified default shipping options" do
      given.default_shipping_options_specified_for(:my_account)
    end

    Given "I have an item in my shopping cart" do
      given.an_item_in_my_shopping_cart(:my_account)
    end

    When "I sign in to my account" do
      ui.sign_in(:my_account)
    end

    When "I choose to check out" do
      ui.choose_to_check_out
    end

    Then "I see my order summary" do
      ui.order_summary.should be_visible
    end

    Then "I see that my default payment options will be used" do
      ui.order_summary.payment_options.should be_account_default_options
    end

    Then "I see that my default shipping options will be used" do
      ui.order_summary.shipping_options.should be_account_default_options
    end

The step definitions contain neither explicitly shared state (instance
variables) nor any logic branches; they are simply wrappers around calls into
the Domain Driver layer. There are a couple of advantages to this approach.

First, because step definitions are so simple, it isn't necessary to force *Very
Specific Wording* on the business analyst/product owner who is writing the
specs. For instance, if she writes "I see a summary of my order" in another
scenario, it's not a big deal to have the following in your step definitions (as
long as the author of the spec confirms that they really mean the same thing):

    Then "I see my order summary" do
      ui.order_summary.should be_visible
    end

    Then "I see a summary of my order" do
      ui.order_summary.should be_visible
    end

The step definitions are nothing more than a natural language reference to an
action in the Domain Driver; there is no overwhelming maintenance cost to the
slight duplication, and it opens up the capacity for more readable Gherkin
specs. The fewer false road blocks you put between your product owner and a
written specification, the easier it becomes to ensure her participation in this
process.

The second advantage is that by pushing all of the complexity down into the
Domain Driver, it's now trivial to reuse the exact same code in
developer-centric integration tests. This ensures you have parity between the
way the automated acceptance tests run and any additional testing that the
development team needs to add in.

Using RSpec, the test implementation would be as follows:

    # spec/integration/purchase_items_in_cart_spec.rb
    
    describe "Purchase Items in Cart" do
      example "Using Existing Billing and Shipping Information" do
        given.existing_account(:my_account)
        given.default_payment_options_specified_for(:my_account)
        given.default_shipping_options_specified_for(:my_account)
        given.an_item_in_my_shopping_cart(:my_account)

        ui.sign_in(:my_account)
        ui.choose_to_check_out

        ui.order_summary.should be_visible
        ui.order_summary.payment_options.should be_account_default_options
        ui.order_summary.shipping_options.should be_account_default_options
      end
    end

### The Domain Driver ###

The Domain Driver layer is where you build up an internal DSL that describes the
business concepts of your application at a fairly high level. It consists of
three top-level drivers: the `APIDriver` (available via `#api`) for interacting
with your application's external API, the `GivenDriver` (available via `#given`)
which really just wraps the `APIDriver` and is used to set up state for your
tests, and the UIDriver (available via `#ui`) for describing the tasks that a
user can accomplish with the application.

#### Test Data ####

`Kookaburra::TestData` is the component via which the `GivenDriver` and the
`UIDriver` share information. For instance, if you create a user account via the
`GivenDriver`, you would store the login credentials for that account in the
`TestData` instance, so the UIDriver knows what to use when you tell it to
`#sign_in`. This is what allows the Cucumber step definitions to remain free
from explicitly shared state.

The `TestData` class can be configured to contain both collections of test data
as well as default data that can be used as a starting point for creating new
resources in the application. To configure `TestData`, call
`Kookaburra.test_data_setup` with a block (usually in your
`lib/my_application/kookaburra.rb` file):

    module MyApplication
      module Kookaburra
        # ...
        ::Kookaburra.test_data_setup do
          provide_collection :animals
          set_default :animal,
            :name => 'horse'
            :size => 'large',
            :number_of_legs => 4
        end
      end
    end

Then, in any context where you have an instance of `TestData` (such as in
`GivenDriver` or `UIDriver`), you can add/retrieve items to/from collections and
access default data:

    class MyApplication::Kookaburra::GivenDriver < Kookaburra::GivenDriver
      def existing_account(nickname)
        default_account_data = test_data.default(:account)
        # do something to create account in application
        # ...
        # make the details of the new account available to the rest of the test
        test_data.accounts[nickname] = account
      end
    end

    class MyApplication::Kookaburra::UIDriver < Kookaburra::UIDriver
      def sign_in(account_nickname)
        # pull stored account details from TestData
        account_info = test_data.accounts[account_nickname]

        # do something to log in using that account_info
      end
    end

#### API Driver ####

The `Kookaburra::APIDriver` is used to interact with an application's external
web services API. You tell Kookaburra about your API by creating a subclass of
`Kookaburra::APIDriver` for your application:

    # lib/my_application/kookaburra/api_driver.rb

    class MyApplication::Kookaburra::APIDriver < Kookaburra::APIDriver
      def create_account(account_data)
        post_as_json 'Account', 'api/v1/accounts', :account => account_data
        hash_from_response_json[:account]
      end
    end

#### Given Driver ####

The `Kookaburra::GivenDriver` is used to create a particular "preexisting"
state within your application's data and ensure you have a handle to that data
(when needed) prior to interacting with the UI. Like the `APIDriver`, you will
create a subclass of `Kookaburra::GivenDriver` in which you will create part of
the Domain Driver DSL for your application:

    # lib/my_application/kookaburra/given_driver.rb

    class MyApplication::Kookaburra::GivenDriver < Kookaburra::GivenDriver
      def existing_account(nickname)
        # grab the default account details and add a unique username and
        # password
        account_data = test_data.default(:account)
        account_data[:username] = "test-user-#{`uuidgen`.strip}"
        account_data[:password] = account_data[:username] + "-password"

        # use the API to create the account in the application
        account_details = api.create_account(account_data)

        # merge in the password (since API doesn't return it) and store details
        # in the TestData instance
        account_details.merge(:password => account_data[:password])
        test_data.accounts[nickname] = account_details
      end
    end

Although there is nothing that actually *prevents* you from either interacting
with the UI or directly manipulating your application via calls into the model
from the `GivenDriver`, both things should be avoided. In the first case, the
`GivenDriver`'s purpose is to describe state that exists *before* the user
interaction that is being tested. Although this state may be the result of a
previous user interaction, your tests will generally be much, much faster if you
are able to create this state via API calls rather than driving a web browser.

In the second case, by avoiding manipulating your applications's state at the
code level and instead doing so via an external API, it is much less likely that
you will be creating a state that your application can't actually get into in a
production environment. Additionally, this opens up the possibility of running
your tests against a "remote" server where you would not have access to the
application internals. ("Remote" in the sense that it is not in the same Ruby
process as your running tests, although it may or may not be on the same
machine.)

#### UI Driver ####

`Kookaburra::UIDriver` provides the necessary tools for driving your
application's user interface using the Window Driver pattern. You will subclass
`Kookaburra::UIDriver` for your application and implement your testing DSL
within your subclass:

    # lib/my_application/kookaburra/ui_driver.rb

    class MyApplication::Kookaburra::UIDriver < Kookaburra::UIDriver
      # makes an instance of MyApplication::Kookaburra::UIDriver::SignInScreen
      # available via the instance method #sign_in_screen
      ui_component :sign_in_screen

      def sign_in(account_nickname)
        account = test_data.accounts[account_nickname]
        navigate_to :sign_in_screen
        sign_in_screen.submit_login(account[:username], account[:password])
      end
    end

### The Window Driver Layer ###

While your `GivenDriver` and `UIDriver` provide a DSL that represents actions
your users can perform in your application, the [Window Driver] [Window Driver]
layer describes the individual user interface components that the user interacts
with to perform these tasks. By describing each interface component using an OOP
approach, it is much easier to maintain your acceptance/integration tests,
because the implementation details of each component are captured in a single
place. If/when that implementation changes, you can---for example---fix every
single test that needs to log a user into the system just by updating the
SignInScreen class.

You describe the various user interface components by sub-classing
`Kookaburra::UIDriver::UIComponent`:

    # lib/my_application/ui_driver/sign_in_screen.rb

    class MyApplication::Kookaburra::UIDriver::SignInScreen < Kookaburra::UIDriver::UIComponent
      component_locator '#new_user_session'
      component_path '/session/new'

      def username
        in_component { browser.find('#session_username').value }
      end

      def username=(new_value)
        fill_in('#session_username', :with => new_value)
      end

      def password
        in_component { browser.find('#session_password').value }
      end

      def password=(new_value)
        fill_in('#session_password', :with => new_value)
      end

      def submit!
        click_on('Sign In')
        no_500_error!
      end

      def submit_login(username, password)
        self.username = username
        self.password = password
        submit!
      end
    end

### The Application Driver Layer ###

`Kookaburra::APIDriver`, `Kookaburra::UIDriver` and
`Kookaburra::UIDriver::UIComponent` rely on the Application Driver layer to
interact with your application. In the case of the `APIDriver`, Kookaburra uses
`Rack::Test` to send HTTP requests to your application. The `UIDriver` and
`UIComponent` rely on whatever is configured as `Kookaburra.adapter`. Presently,
we have only used Capybara as the application driver for Kookaburra:

    Kookaburra.adapter = Capybara

It's possible that something other than Capybara could be passed in, as long as
that something presented the same API. In reality, using something other than
Capybara is likely to require some changes to Kookaburra itself. If you have a
particular interest in making this work, please feel free to fork the project
and send us a [GitHub pull request] [Pull Request] with your changes.

## Contributing to kookaburra ##
 
* Check out the latest master to make sure the feature hasn't been implemented
  or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it
  and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to
  have your own version, or is otherwise necessary, that is fine, but please
  isolate to its own commit so I can cherry-pick around it.
* Send us a [pull request] [Pull Request]

## Copyright ##

Copyright &copy; 2011 John Wilger. See LICENSE.txt for
further details.

[Window Driver]: http://martinfowler.com/eaaDev/WindowDriver.html "Window Driver - Martin Fowler"
[Kookaburra Gem]: https://rubygems.org/gems/kookaburra "kookaburra | RubyGems.org | your community gem host"
[Rack]: http://rack.rubyforge.org/ "Rack: a Ruby Webserver Interface"
[Capybara]: https://github.com/jnicklas/capybara "jnicklas/capybara - GitHub"
[RSpec]: http://rspec.info "RSpec.info: home"
[Cucumber]: http://cukes.info/ "Cucumber - Making BDD fun"
[Pull Request]: https://github.com/projectdx/kookaburra/pull/new/master "Send a pull request - GitHub"
