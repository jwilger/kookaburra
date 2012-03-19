# Kookaburra #

Kookaburra is a framework for implementing the [Window Driver] [Window Driver] pattern in
order to keep acceptance tests maintainable.

## WARNING: Documentation Out of Date ##

The master branch on GitHub currently contains a number of significant changes
that are not yet reflected in the following documentation.

## Installation ##

Kookaburra is available as a Rubygem and [published on Rubygems.org] [Kookaburra Gem],
so installation is trivial:

    gem install kookaburra

If you're using [Bundler](http://gembundler.com/) for your project, just add the
following:

    group :development, :test do
      gem 'kookaburra'
    end

## Setup ##

Kookaburra abstracts some common patterns for implementing the Window Driver
pattern for tests of Ruby web applications built on [Rack] [Rack]. You will need
to tell Kookaburra which classes contain the specific Domain Driver
implementations for your application as well as which driver to use for running
the tests (currently only tested with [Capybara] [Capybara]).

### ActiveRecord and Database Transactions ###

Kookaburra currently uses Rack::Test as the underlying implementation for its
APIDriver classes. This poses a problem when you want to run your UI tests via a
driver other than Rack::Test such as Selenium, because the APIDriver sets up
your test data using a different database connection than the process that runs
the server against which Selenium executes, and they do not have access to the
same transaction.

One way to handle this problem is to force ActiveRecord to use the same
connection in both the main thread and the thread that is spun up by Capybara to
run the application for Selenium testing. You can do so by requiring
`kookaburra/utils/active_record_shared_connection` within your Kookaburra setup.

In the near future, we plan to change Kookaburra to execute *both* its APIDriver
and UIDriver against an actual server and ditch Rack::Test. Not only will this
help avoid this specific problem, but it will move towards the goal of being
able to (optionally) run these tests on a completely different machine than the
running application.

### RSpec ###

For [RSpec] [RSpec] integration tests, just add the following to
`spec/support/kookaburra_setup.rb`:

    # only if using ActiveRecord and a browser driver other than Rack::Test for
    # UI testing
    require 'kookaburra/utils/active_record_shared_connection'

    require 'kookaburra/test_helpers'
    require 'my_app/kookaburra/api_driver'
    require 'my_app/kookaburra/given_driver'
    require 'my_app/kookaburra/ui_driver'

    Kookaburra.configuration = {
      :api_driver_class => MyApp::Kookaburra::APIDriver,
      :given_driver_class => MyApp::Kookaburra::GivenDriver,
      :ui_driver_class => MyApp::Kookaburra::UIDriver,
      :browser => Capybara,
      :rack_app => Capybara.app,
      :server_error_detection => { |browser|
        browser.has_css?('head title', :text => 'Internal Server Error')
      }
    }

    RSpec.configure do |c|
      c.include(Kookaburra::TestHelpers, :type => :request)
    end

### Cucumber ###

For [Cucumber] [Cucumber], add the following to `features/support/kookaburra_setup.rb`:

    # only if using ActiveRecord and a browser driver other than Rack::Test for
    # UI testing
    require 'kookaburra/utils/active_record_shared_connection'

    require 'kookaburra/test_helpers'
    require 'my_app/kookaburra/api_driver'
    require 'my_app/kookaburra/given_driver'
    require 'my_app/kookaburra/ui_driver'

    Kookaburra.configuration = {
      :api_driver_class => MyApp::Kookaburra::APIDriver,
      :given_driver_class => MyApp::Kookaburra::GivenDriver,
      :ui_driver_class => MyApp::Kookaburra::UIDriver,
      :browser => Capybara,
      :rack_app => Capybara.app,
      :server_error_detection => { |browser|
        browser.has_css?('head title', :text => 'Internal Server Error')
      }
    }

    World(Kookaburra::TestHelpers)

This will cause the #k, #given and #ui methods will be available in your
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
5. The **Application Driver** (Capybara and Kookaburra::RackDriver)

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

**Test assertions always belong within the test implementation layer.** Some testing
frameworks such as RSpec add methods like `#should` to `Object`, which has the
effect of poisoning the entire Ruby namespace with these methods---if you are
using RSpec, you can call `#should` anywhere in your code and it will work when
RSpec is loaded. Do not be tempted to call a testing library's Object decorators
anywhere outside of your test implementation (such as within `UIDriver` or
`UIComponent` subclasses.) Doing so will tightly couple your Domain Driver
and/or Window Driver implementation to a specific testing library.

`Kookaburra::UIDriver::UIComponent` does provide an `#assert` method for use
inside your own UIComponents. This method exists to verify preconditions and
provide more informative error messages; it is not intended to be used to make
test verifications.

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
      ui.order_summary.payment_options.should == k.get_data(:default_payment_options)[:my_account]
    end

    Then "I see that my default shipping options will be used" do
      ui.order_summary.shipping_options.should == k.get_data(:default_shipping_options)[:my_account]
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
        ui.order_summary.payment_options.should == k.get_data(:default_payment_options)[:my_account]
        ui.order_summary.shipping_options.should == k.get_data(:default_shipping_options)[:my_account]
      end
    end

### The Domain Driver ###

The Domain Driver layer is where you build up an internal DSL that describes the
business concepts of your application at a fairly high level. It consists of two
top-level drivers: the `GivenDriver` (available via `#given`) used to set up
state for your tests and the UIDriver (available via `#ui`) for describing the
tasks that a user can accomplish with the application.

#### Test Data ####

`Kookaburra::TestData` is the component via which the `GivenDriver` and the
`UIDriver` share information. For instance, if you create a user account via the
`GivenDriver`, you would store the login credentials for that account in the
`TestData` instance, so the `UIDriver` knows what to use when you tell it to
`#sign_in`. This is what allows the Cucumber step definitions to remain free
from explicitly shared state.

Kookaburra automatically configures your `GivenDriver` and your `UIDriver` to share
a `TestData` instance, which is available to both of them via their `#test_data`
method.

The `TestData` instance will return a `TestData::Collection` for any method
called on the object. The `TestData::Collection` object behaves like a `Hash`
for the most part, however it will raise a `Kookaburra::UnknownKeyError` if you
try to access a key that has not yet been assigned a value.

Here's a quick example of TestData behavor:

    test_data = TestData.new

    test_data.widgets[:widget_a] = {'name' => 'Widget A'}

    test_data.widgets[:widget_a]
    #=> {'name' => 'Widget A'}
    
    # this will raise a Kookaburra::UnknownKeyError
    test_data.widgets[:widget_b]

#### API Driver ####

The `Kookaburra::APIDriver` is used to interact with an application's external
web services API. You tell Kookaburra about your API by creating a subclass of
`Kookaburra::APIDriver` for your application. Because different applications may
implement different types of APIs, Kookaburra will provide more than one base
APIDriver class. At the moment, only a JSON API is supported via
`Kookaburra::JsonApiDriver`:

    # lib/my_app/kookaburra/api_driver.rb

    class MyApp::Kookaburra::APIDriver < Kookaburra::JsonApiDriver
      def create_account(account_data)
        post '/api/v1/accounts', account_data
      end
    end

Regardless of the type of APIDriver subclass, the contents of your application's
APIDriver should consist mainly of mappings between discrete actions and HTTP
requests to the specified URL paths. Each driver will implement `#post`, `#get`,
`#put`, `#head`, and `#delete` in such a way that any Ruby data structure
provided as parameters will be appropriately translated to the API's required
data format, and any response body from the API request will be translated into
a Ruby data structure and returned.

#### Given Driver ####

The `Kookaburra::GivenDriver` is used to create a particular "preexisting" state
within your application's data and ensure you have a handle to that data (when
needed) prior to interacting with the UI. You will create a subclass of
`Kookaburra::GivenDriver` in which you will create part of the Domain Driver DSL
for your application:

    # lib/my_app/kookaburra/given_driver.rb

    class MyApp::Kookaburra::GivenDriver < Kookaburra::GivenDriver
      def existing_account(nickname)
        account_data = {'display_name' => 'John Doe', 'password' => 'a password'}
        account_data['username'] = "test-user-#{`uuidgen`.strip}"

        # use the API to create the account in the application
        result = api.create_account(account_data)

        # merge in the password, since API (hopefully!) doesn't return it, and
        # store details in the TestData instance
        result.merge!('password' => account_data['password'])
        test_data.accounts[nickname] = account_details
      end
    end

Although there is nothing that actually *prevents* you from either interacting
with the UI or directly manipulating your application via calls into the model
from the `GivenDriver`, both should be avoided. In the first case, the
`GivenDriver`'s purpose is to describe state that exists *before* the user
interaction that is being tested. Although this state may be the result of a
previous user interaction, your tests will be much, much faster if you create
this state via API calls rather than driving a web browser.

In the second case, by avoiding the manipulation of your applications's state at the
code level and instead doing so via an external API, it is much less likely that
you will create a state that your application can't actually get into in a
production environment. Additionally, this opens up the possibility of running
your tests against a "remote" server where you would not have access to the
application internals. ("Remote" in the sense that it is not in the same Ruby
process as your running tests, although it may or may not be on the same
machine. Note that this is not currently possible with Kookaburra due to our
reliance on Rack::Test.)

#### UI Driver ####

`Kookaburra::UIDriver` provides the necessary tools for driving your
application's user interface using the Window Driver pattern. You will subclass
`Kookaburra::UIDriver` for your application and implement your testing DSL
within your subclass:

    # lib/my_app/kookaburra/ui_driver.rb

    class MyApp::Kookaburra::UIDriver < Kookaburra::UIDriver
      # makes an instance of MyApp::Kookaburra::UIDriver::SignInScreen
      # available via the instance method #sign_in_screen
      ui_component :sign_in_screen, SignInScreen

      def sign_in(account_nickname)
        account = test_data.accounts[account_nickname]
        sign_in_screen.show
        sign_in_screen.submit_login(account['username'], account['password'])
      end
    end

### The Window Driver Layer ###

While your `GivenDriver` and `UIDriver` provide a DSL that represents actions
your users can perform in your application, the [Window Driver] [Window Driver]
layer describes the individual user interface components that the user interacts
with to perform these tasks. By describing each interface component using an OOP
approach, it is much easier to maintain your acceptance/integration tests,
because the implementation details of each component are captured in a single
place. For example, if/when the implementation of your application's sign in
screen changes, you can fix every single test that needs to log a user into the
system just by updating the `SignInScreen` class.

You describe the various user interface components by sub-classing
`Kookaburra::UIDriver::UIComponent`:

    # lib/my_app/ui_driver/sign_in_screen.rb

    class MyApp::Kookaburra::UIDriver::SignInScreen < Kookaburra::UIDriver::UIComponent
      def component_locator
        '#new_user_session'
      end

      def component_path
        '/session/new'
      end

      def username
        find('#session_username').value
      end

      def username=(new_value)
        fill_in '#session_username', :with => new_value
      end

      def password
        find('#session_password').value
      end

      def password=(new_value)
        fill_in '#session_password', :with => new_value
      end

      def submit
        click_on('Sign In')
      end

      def submit_login(username, password)
        self.username = username
        self.password = password
        submit
      end
    end

### The Application Driver Layer ###

`Kookaburra::APIDriver`, `Kookaburra::UIDriver` and
`Kookaburra::UIDriver::UIComponent` rely on the Application Driver layer to
interact with your application. In the case of the `APIDriver`, Kookaburra uses
`Kookaburra::RackDriver` to send HTTP requests to your application. The `UIDriver` and
`UIComponent` rely on whatever is passed to `Kookaburra.new` as the `:browser`
option. Presently, we have only used Capybara as the application driver for Kookaburra.

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
