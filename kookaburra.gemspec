# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "kookaburra"
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Renewable Funding, LLC"]
  s.date = "2012-01-18"
  s.description = "Cucumber + Capybara = Kookaburra? It made sense at the time."
  s.email = "devteam@renewfund.com"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    ".document",
    ".rvmrc",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE.txt",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "kookaburra.gemspec",
    "lib/kookaburra.rb",
    "lib/kookaburra/api_driver.rb",
    "lib/kookaburra/given_driver.rb",
    "lib/kookaburra/test_data.rb",
    "lib/kookaburra/ui_driver.rb",
    "lib/kookaburra/ui_driver/mixins/has_browser.rb",
    "lib/kookaburra/ui_driver/mixins/has_strategies.rb",
    "lib/kookaburra/ui_driver/mixins/has_subcomponents.rb",
    "lib/kookaburra/ui_driver/mixins/has_ui_component.rb",
    "lib/kookaburra/ui_driver/ui_component.rb",
    "lib/requires.rb",
    "test/helper.rb",
    "test/kookaburra/ui_driver_test.rb",
    "test/kookaburra_test.rb"
  ]
  s.homepage = "http://github.com/projectdx/kookaburra"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.15"
  s.summary = "WindowDriver testing pattern for Ruby apps"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<i18n>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 3.0"])
      s.add_runtime_dependency(%q<rack-test>, [">= 0"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
      s.add_development_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_development_dependency(%q<rcov>, [">= 0"])
      s.add_development_dependency(%q<reek>, ["~> 1.2.8"])
    else
      s.add_dependency(%q<i18n>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 3.0"])
      s.add_dependency(%q<rack-test>, [">= 0"])
      s.add_dependency(%q<minitest>, [">= 0"])
      s.add_dependency(%q<yard>, ["~> 0.6.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0.0"])
      s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
      s.add_dependency(%q<rcov>, [">= 0"])
      s.add_dependency(%q<reek>, ["~> 1.2.8"])
    end
  else
    s.add_dependency(%q<i18n>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 3.0"])
    s.add_dependency(%q<rack-test>, [">= 0"])
    s.add_dependency(%q<minitest>, [">= 0"])
    s.add_dependency(%q<yard>, ["~> 0.6.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0.0"])
    s.add_dependency(%q<jeweler>, ["~> 1.6.4"])
    s.add_dependency(%q<rcov>, [">= 0"])
    s.add_dependency(%q<reek>, ["~> 1.2.8"])
  end
end

