# encoding: utf-8

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task :default => :spec
RSpec::Core::RakeTask.new

require 'reek/rake/task'
Reek::Rake::Task.new do |t|
  t.fail_on_error = true
  t.verbose = false
  t.source_files = 'lib/**/*.rb'
end

require 'yard'
YARD::Rake::YardocTask.new
