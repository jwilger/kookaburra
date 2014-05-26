# encoding: utf-8

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task :default => :spec
RSpec::Core::RakeTask.new

desc 'Runs reek to detect code smells'
task :reek do
  sh 'reek lib/**/*.rb'
end

require 'yard'
YARD::Rake::YardocTask.new
