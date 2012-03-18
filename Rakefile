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

desc "Generate code coverage"
RSpec::Core::RakeTask.new(:coverage) do |t|
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
end

require 'reek/rake/task'
Reek::Rake::Task.new do |t|
  t.fail_on_error = true
  t.verbose = false
  t.source_files = 'lib/**/*.rb'
end

require 'yard'
YARD::Rake::YardocTask.new

namespace :rackup do
  namespace :json_api_app do
    desc "Start the JsonApiApp service"
    task :start do
      puts `rackup -Ispec/fixtures -p 4567 -P rackup-json_api_app.pid -D spec/fixtures/kookaburra/rack_apps/json_api_app.ru`
    end

    desc "Stop the JsonApiApp service"
    task :stop do
      puts `kill -9 #{File.read('rackup-json_api_app.pid')}`
      puts `rm rackup-json_api_app.pid`
    end
  end
end
