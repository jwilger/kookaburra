require 'kookaburra/exceptions'
require 'kookaburra/test_data'
require 'kookaburra/given_driver'
require 'kookaburra/ui_driver'

# Kookaburra provides the top-level API that you will access in your test
# implementation, namely the {#given}, {#ui}, and the {#get_data} methods.
#
# The Kookaburra object ensures that your GivenDriver and UIDriver share the
# same state with regard to any fixture data that is created during your test
# run. As such, it is important to ensure that a new instance of Kookaburra is
# created for each individual test, otherwise you may wind up with test state
# bleeding over from one test to the next.
#
# @example RSpec setup
#   # in 'lib/my_app/kookaburra/api_driver.rb'
#   module MyApp
#     module Kookaburra
#       class APIDriver < ::Kookaburra::JsonApiDriver
#         #...
#       end
#     end
#   end
#
#   # in 'lib/my_app/kookaburra/given_driver.rb'
#   module MyApp
#     module Kookaburra
#       class GivenDriver < ::Kookaburra::GivenDriver
#         #...
#       end
#     end
#   end
#
#   # in 'lib/my_app/kookaburra/ui_driver.rb'
#   module MyApp
#     module Kookaburra
#       class UIDriver < ::Kookaburra::UIDriver
#         #...
#       end
#     end
#   end
#
#   # in 'spec/support/kookaburra_setup.rb'
#   require 'kookaburra'
#   require 'my_app/kookaburra/api_driver'
#   require 'my_app/kookaburra/given_driver'
#   require 'my_app/kookaburra/ui_driver'
#   
#   module KookaburraSetup
#     def ui
#       k.ui
#     end
#   
#     def given
#       k.given
#     end
#   
#     def k
#       @kookaburra ||= Kookaburra.new(given_driver_class: MyApp::Kookaburra::GivenDriver,
#                                      api_driver_class: MyApp::Kookaburra::APIDriver,
#                                      ui_driver_class: MyApp::Kookaburra::UIDriver,
#                                      browser: Capybara)
#     end
#   end
#
#   RSpec.configure do |c|
#     c.include RSpec::Rails::RequestExampleGroup, type: :request, example_group: {file_path: c.escaped_path(%w[spec acceptance])}
#     c.include(KookaburraSetup, type: :request)
#   end
#
#   # in 'spec/acceptance/my_spec.rb'
#   describe "Something" do
#     example "does something" do
#       given.a_thing(:foo)
#       ui.create_a_new_thing(:bar)
#       ui.list_of_things.things.should == k.get_data(:things).slice(:foo, :bar)
#     end
#   end
class Kookaburra
  extend DependencyAccessor

  dependency_accessor :given_driver_class, :api_driver_class, :ui_driver_class, :browser

  def initialize(options = {})
    @given_driver_class = options[:given_driver_class]
    @api_driver_class   = options[:api_driver_class]
    @ui_driver_class    = options[:ui_driver_class]
    @browser            = options[:browser]
  end

  def given
    given_driver_class.new(:test_data => test_data, :api => api)
  end

  def ui
    ui_driver_class.new(:test_data => test_data, :browser => browser)
  end

  def get_data(collection_name)
    test_data.send(collection_name).dup.freeze
  end

  private

  def api
    api_driver_class.new(RackDriver.new(browser.app))
  end

  def test_data
    @test_data ||= TestData.new
  end

end
