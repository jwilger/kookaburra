# encoding: utf-8

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

task :default => [:spec, 'spec:slow']

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = "-t ~slow"
end

namespace :spec do
  RSpec::Core::RakeTask.new(:slow) do |t|
    t.rspec_opts = "-t slow"
  end
end

desc 'Runs reek to detect code smells'
task :reek do
  sh 'reek lib/**/*.rb'
end

require 'yard'
YARD::Rake::YardocTask.new
