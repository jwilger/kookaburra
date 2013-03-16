require 'capybara'
require 'thwait'
require 'find_a_port'

# Handles Starting/Stopping Rack Server for Tests
#
# `RackAppServer` is basically a wrapper around `Capybara::Server` that
# makes it a bit easier to use Kookaburra with a Rack application (such
# as Rails or Sinatra) when you want to run your tests locally against a
# server that is only running for the duration of the tests. You simply
# tell it how to get ahold of your Rack application (see `#initialize`)
# and then call `#boot` before your tests run and `#shutdown` after your
# tests run.
#
# @example using RSpec
#   # put this in something like `spec_helper.rb`
#   app_server = Kookaburra::RackAppServer.new do
#     # unless you are in JRuby, this stuff all runs in a new fork later
#     # on
#     ENV['RAILS_ENV'] = 'test'
#     require File.expand_path(File.join('..', '..', 'config', 'environment'), __FILE__)
#     MyAppName::Application
#   end
#   RSpec.configure do
#     c.before(:all) do
#       app_server.boot
#     end
#     c.after(:all) do
#       app_server.shutdown
#     end
#   end
class Kookaburra::RackAppServer
  attr_reader :port

  # Sets up a new app server
  #
  # @param startup_timeout [Integer] (10) The maximum number of seconds
  #        to wait for the app server to respond
  # @yieldreturn [#call] block must return a valid Rack application
  def initialize(startup_timeout=10, &rack_app_initializer)
    self.startup_timeout = startup_timeout
    self.rack_app_initializer = rack_app_initializer
    self.port = FindAPort.available_port
  end

  # Start the application server
  #
  # This will launch the server on a (detected to be) available port. It
  # will then monitor that port and only return once the app server is
  # responding (or after a 10 second timeout).
  def boot
    if defined?(JRUBY_VERSION)
      thread_app_server
    else
      fork_app_server
    end
    wait_for_app_to_respond
  end

  def shutdown
    return if defined?(JRUBY_VERSION)
    Process.kill(9, rack_server_pid)
    Process.wait
  end

  private

  attr_accessor :rack_app_initializer, :rack_server_pid, :startup_timeout
  attr_writer :port

  def thread_app_server
    Thread.new { start_server }
  end

  def fork_app_server
    self.rack_server_pid = fork do
      start_server
    end
  end

  def start_server
    app = rack_app_initializer.call
    Capybara.server_port = port
    Capybara::Server.new(app).boot
    # This ensures that this forked process keeps running, because the
    # actual server is started in a thread by Capybara.
    ThreadsWait.all_waits(Thread.list)
  end

  def wait_for_app_to_respond
    begin
      Timeout.timeout(startup_timeout) do
        next until running?
      end
    rescue Timeout::Error
      raise "Application does not seem to be responding on port #{port}."
    end
  end

  def running?
    res = Net::HTTP.start('localhost', port) { |http| http.get('/__identify__') }
    if res.is_a?(Net::HTTPSuccess) or res.is_a?(Net::HTTPRedirection)
      true
    else
      false
    end
  rescue Errno::ECONNREFUSED, Errno::EBADF, Errno::ETIMEDOUT
    false
  end
end
