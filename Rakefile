# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "kookaburra"
  gem.homepage = "http://github.com/projectdx/kookaburra"
  gem.license = "MIT"
  gem.summary = %Q{WindowDriver testing pattern for Ruby apps}
  gem.description = %Q{Cucumber + Capybara = Kookaburra? It made sense at the time.}
  gem.email = "johnwilger@gmail.com"
  gem.authors = ["John Wilger", "Sam Livingston-Gray", "Ravi Gadad"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core/rake_task'

task :default => :spec

desc 'Run specs'
RSpec::Core::RakeTask.new

require 'reek/rake/task'
Reek::Rake::Task.new do |t|
  t.fail_on_error = true
  t.verbose = false
  t.source_files = 'lib/**/*.rb'
end

require 'yard'
YARD::Rake::YardocTask.new

desc "Run rake on all supported rubies"
task :all_rubies do
  rubies = %w[ruby-1.9.3 ruby-1.9.2 ree-1.8.7 ruby-1.8.7]
  rubies.each do |ruby_version|
    puts "Testing with #{ruby_version}"
    system "rvm #{ruby_version}@kookaburra do rake" \
      or raise "Failed to run rake with #{ruby_version}!"
  end
end
