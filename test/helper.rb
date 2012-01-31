require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest/unit'
require 'minitest/autorun'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'kookaburra'

class MiniTest::Unit::TestCase
  # TODO: make this better, so that there is only one failure message
  def assert_raises_with_message(expected_exception, expected_message, &block)
    begin
      yield
      flunk "Expected to raise a #{expected_exception}"
    rescue => e
      assert_kind_of expected_exception, e
      assert_match expected_message, e.message
    end
  end
end

MiniTest::Unit.autorun
