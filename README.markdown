# Kookaburra #

Kookaburra is a framework for implementing the [Window Driver] [1] pattern in
order to keep acceptance tests maintainable.

[1]: http://martinfowler.com/eaaDev/WindowDriver.html "Window Driver - Martin Fowler"

## Setup ##

Kookaburra itself abstracts some common patterns for implementing the Window
Driver pattern for tests of Ruby web applications built on Rack. You will need
to tell Kookaburra which classes contain the specific Domain Driver
implementations for your application as well as which driver to use for running
the tests (currently only tested with Capybara). The details of setting up your
Domain Driver layer are discussed below, but in general you will need the
following in a locations such as `lib/my_application/kookaburra.rb` (replace
`MyApplication` with a module name suitable to your actual application:

    module MyApplication
      module Kookaburra
        ::Kookaburra.adapter = Capybara

        # Note: the following assigned classes are defined under your
        # application's namespace, e.g. MyApplication::Kookaburra::TestData
        ::Kookaburra.test_data = TestData
        ::Kookaburra.api_driver = APIDriver
        ::Kookaburra.given_driver = GivenDriver
        ::Kookaburra.ui_driver = UIDriver
      end
    end

### RSpec ###

For RSpec integration tests, just add the following to
`spec/support/kookaburra.rb`:

    RSpec.configure do |c|
      c.include(Kookaburra, :type => :request)
    end

### Cucumber ###

For Cucumber, add the following to `features/support/kookaburra_setup.rb`:

    Kookaburra.adapter = Capybara
    World(Kookaburra)

    Before do
      kookaburra_reset!
    end

This will cause the #api, #given and #ui methods will be available in your
Cucumber step definitions.

## Defining Your Testing DSL ##

Kookaburra attempts to extract some common patterns that make it easier to use
the Window Driver pattern along with various Ruby testing frameworks, but you
still need to define your own testing DSL. An acceptance testing stack using
Kookaburra has the following four layers:

1. The **Business Specification Language** (Cucumber scenarios and step definitions)
2. The **Domain Driver** (Kookaburra::GivenDriver, Kookaburra::UIDriver and
   Kookaburra::APIDriver)
3. The **Window Driver** (Kookaburra::UIDriver::UIComponent)
4. The **Application Driver** (Capybara and Rack::Test)

### The Business Specification Language ###

The business specification language consists of the highest-level descriptions
of a feature that are suitable for sharing with the non/less-technical
stakeholders on a project.

When using Cucumber with Kookaburra, your scenarios and step definitions might
look as follows:

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

And the step definitions:

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

Note that the step definitions contain neither explicitly shared state
(instance variables) nor any logic branches; they are simply wrappers around
calls into the Domain Driver layer. There are several advantages to this
approach. First, because step definitions are so simple, it isn't necessary to
force *Very Specific Wording* on the business analyst/product owner who is writing
the specs. For instance, if they write "I see a summary of my order" in another
scenario, it's not a big deal to have the following in your step definitions (as
long as it's obvious that they really mean the same thing):

    Then "I see my order summary" do
      ui.order_summary.should be_visible
    end

    Then "I see a summary of my order" do
      ui.order_summary.should be_visible
    end

Because both of these step definitions are merely providing a natural language
reference to an action in the Domain Driver, there is no overwhelming
maintenance cost to the slight duplication, and it opens up the capacity for
more readable Gherkin specs.

Second, because all of the complexity is pushed down into the Domain Driver,
it's now trivial to reuse the exact same code in developer-centric integration
tests, which ensures you have parity between the way the automated acceptance
tests run and any additional testing that the development team needs to add in.
You could write the same test using just RSpec as follows:

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

## Contributing to kookaburra ##
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright ##

Copyright &copy; 2011 John Wilger. See LICENSE.txt for
further details.

