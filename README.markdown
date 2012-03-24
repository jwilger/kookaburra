# Kookaburra #

Kookaburra is a framework for implementing the [Window Driver] [Window Driver] pattern in
order to keep acceptance tests maintainable.

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
testing pattern for web applications. You will need to tell Kookaburra which
classes contain the specific Domain Driver implementations for your application
as well as which driver to use for running the tests (currently only tested with
[Capybara] [Capybara]).

Kookaburra is designed to run tests agains a remote web server (although that
server could be running on the same machine, it doesn't need to be), and it is
the responsibility of the test implementation to ensure that the server is
running. Take a look at Kookaburra's own integration specs for one example of
how to achieve this for a [Rack-based] [Rack] application. (Note that you cannot
easily start the application server in a separate thread. Because Ruby uses
green threads, the HTTP library used in the APIDriver will block while making
its requests and prevent the application server thread from responding.)

The fact that Kookaburra runs against a remote server means that *it is not
limited to testing only Ruby web applications*. As long as your application
exposes a web-service API for use by the GivenDriver and an HTML user interface
for use by the UIDriver, you can use Kookaburra to test it. Also, as long as
you're careful with both your application and test designs, you're not limited
to running your tests only in an isolated testing environment; you could run the
same test suite you use for development against your production systems and even
repurpose your Kookaburra-based tests for load-testing and similar applications.

### RSpec ###

For [RSpec] [RSpec] integration tests, just add the following to
`spec/support/kookaburra_setup.rb`:

    require 'kookaburra/test_helpers'
    require 'my_app/kookaburra/given_driver'
    require 'my_app/kookaburra/ui_driver'

    # :app_host below should be set to whatever the root URL of your running
    # application is.
    Kookaburra.configuration = {
      :given_driver_class => MyApp::Kookaburra::GivenDriver,
      :ui_driver_class => MyApp::Kookaburra::UIDriver,
      :app_host => 'http://my_app.example.com:1234',
      :browser => Capybara,
      :server_error_detection => { |browser|
        browser.has_css?('head title', :text => 'Internal Server Error')
      }
    }

    RSpec.configure do |c|
      c.include(Kookaburra::TestHelpers, :type => :request)
    end

### Cucumber ###

For [Cucumber] [Cucumber], add the following to `features/support/kookaburra_setup.rb`:

    require 'kookaburra/test_helpers'
    require 'my_app/kookaburra/given_driver'
    require 'my_app/kookaburra/ui_driver'

    # :app_host below should be set to whatever the root URL of your running
    # application is.
    Kookaburra.configuration = {
      :given_driver_class => MyApp::Kookaburra::GivenDriver,
      :ui_driver_class => MyApp::Kookaburra::UIDriver,
      :app_host => 'http://my_app.example.com:1234',
      :browser => Capybara,
      :server_error_detection => { |browser|
        browser.has_css?('head title', :text => 'Internal Server Error')
      }
    }

    World(Kookaburra::TestHelpers)

This will cause the #k, #given and #ui methods will be available in your
Cucumber step definitions.

## Defining Your Testing DSL ##

Kookaburra extracts some common patterns that make it easier to use the Window
Driver pattern along with various Ruby testing frameworks, but you still need to
define your own testing DSL. An acceptance testing stack using Kookaburra has
the following layers:

1. The **Business Specification Language** (Cucumber scenarios or other
   spcification documents)
2. The **Test Implementation** (Cucumber step definitions, RSpec example blocks,
   etc.)
3. The **Domain Driver** (Kookaburra::GivenDriver and Kookaburra::UIDriver)
4. The **Window Driver** (Kookaburra::UIDriver::UIComponent)
5. The **Application Driver** (Capybara and Kookaburra::APIDriver)

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
all, because the actual business concepts described would not change (and
although Kookaburra's focus is on testing web applications, it could likely be
adapted to other environments.)

### The Test Implementation ###

The Test Implementation layer exists as the line in between the Business
Specification Language and the Domain Driver, and it includes Cucumber step
definitions, RSpec example blocks, Test::Unit tests, etc. At this layer, your
code orchestrates calls into the Domain Driver to mimic user interactions under
various conditions and make assertions about the results.

**Test assertions always belong within the test implementation layer.** Some
testing frameworks such as RSpec add methods like `#should` to `Object`, which
has the effect of poisoning the entire Ruby namespace with these methods---if
you are using RSpec, you can call `#should` anywhere in your code and it will
work when RSpec is loaded. Do not be tempted to call a testing library's Object
decorators anywhere outside of your test implementation (such as within
`UIDriver` or `UIComponent` subclasses.) Doing so will tightly couple your
Domain Driver and/or Window Driver implementation to a specific testing library.

`Kookaburra::UIDriver::UIComponent` provides an `#assert` method for use inside
your own UIComponents. This method exists to verify preconditions and provide
more informative error messages; it is not intended to be used for test
verifications.

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

#### Mental Model ####

`Kookaburra::MentalModel` is the component via which the `GivenDriver` and the
`UIDriver` share information, and it is intended to represent your application
user's mental picture of the data they are working with. For instance, if you
create a user account via the `GivenDriver`, you would store the login
credentials for that account in the `MentalModel` instance, so the `UIDriver`
knows what to use when you tell it to `#sign_in`. This is what allows the
Cucumber step definitions to remain free from explicitly shared state.

Kookaburra automatically configures your `GivenDriver` and your `UIDriver` to
share a `MentalModel` instance, which is available to both of them via their
`#mental_model` method.

The `MentalModel` instance will return a `MentalModel::Collection` for any method
called on the object. The `MentalModel::Collection` object behaves like a `Hash`
for the most part, however it will raise a `Kookaburra::UnknownKeyError` if you
try to access a key that has not yet been assigned a value.

Here's a quick example of MentalModel behavor:

    mental_model = MentalModel.new

    mental_model.widgets[:widget_a] = {'name' => 'Widget A'}

    mental_model.widgets[:widget_a]
    #=> {'name' => 'Widget A'}
    
    # this will raise a Kookaburra::UnknownKeyError
    mental_model.widgets[:widget_b]

#### Given Driver ####

The `Kookaburra::GivenDriver` is used to create a particular "preexisting" state
within your application's data and ensure you have a handle to that data (when
needed) prior to interacting with the UI. You will create a subclass of
`Kookaburra::GivenDriver` in which you will create part of the Domain Driver DSL
for your application:

    # lib/my_app/kookaburra/given_driver.rb

    class MyApp::Kookaburra::GivenDriver < Kookaburra::GivenDriver
      # Specify the APIDriver to use
      def api
        @api ||= MyApp::Kookaburra::APIDriver.new(:app_host => initialization_options[:app_host])
      end

      def existing_account(nickname)
        account_data = {'display_name' => 'John Doe', 'password' => 'a password'}
        account_data['username'] = "test-user-#{`uuidgen`.strip}"

        # use the API to create the account in the application
        result = api.create_account(account_data)

        # merge in the password, since API (hopefully!) doesn't return it, and
        # store details in the MentalModel instance
        result.merge!('password' => account_data['password'])
        mental_model.accounts[nickname] = account_details
      end
    end

Although there is nothing that actually *prevents* you from interacting with the
UI in the `GivenDriver`, you should avoid doing so. The `GivenDriver`'s purpose
is to describe state that exists *before* the user interaction that is being
tested. Although this state may be the result of a previous user interaction,
your tests will be much, much faster if you create this state via API calls
rather than driving a web browser.

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

      def get_account(id)
        get '/api/v1/accounts/%d' % id
      end
    end

Regardless of the type of APIDriver, the content of your application's APIDriver
should consist mainly of mappings between discrete actions and HTTP requests to
the specified URL paths. Each driver will implement `#post`, `#get`, `#put` and
`#delete` in such a way that any Ruby data structure provided as parameters will
be appropriately translated to the API's required data format, and any response
body from the API request will be translated into a Ruby data structure and
returned.

#### UI Driver ####

`Kookaburra::UIDriver` provides the necessary tools for driving your
application's user interface with the Window Driver pattern. You will subclass
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
the [Patron] [Patron] library to send HTTP requests to your application. The
`UIDriver` and `UIComponent` rely on whatever is passed to `Kookaburra.new` as
the `:browser` option. Presently, we have only used Capybara as the application
driver for Kookaburra.

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
[Patron]: https://github.com/toland/patron "toland/patron"
