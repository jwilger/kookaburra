require 'kookaburra/exception_classes'
require 'kookaburra/test_data'
require 'kookaburra/given_driver'
require 'kookaburra/api_driver'
require 'kookaburra/ui_driver'

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

  private

  def api
    api_driver_class.new
  end

  def test_data
    @test_data ||= TestData.new
  end

end
