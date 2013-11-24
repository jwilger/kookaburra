# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kookaburra/version'

Gem::Specification.new do |spec|
  spec.name          = "kookaburra"
  spec.version       = Kookaburra::VERSION
  spec.authors       = ["John Wilger", "Sam Livingston-Gray", "Ravi Gadad"]
  spec.email         = ["johnwilger@gmail.com"]
  spec.description   = %q{Cucumber + Capybara = Kookaburra? It made sense at the time.}
  spec.summary       = %q{Window Driver pattern for acceptance tests}
  spec.homepage      = "http://johnwilger.com/kookaburra/"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'rest-client'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "capybara"
  spec.add_development_dependency "capybara-webkit"
  spec.add_development_dependency "reek"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "kramdown"
  spec.add_development_dependency "sinatra"
  spec.add_development_dependency "uuid"
  spec.add_development_dependency "find_a_port"
  spec.add_development_dependency "json"
end
