require_relative "lib/restomatic/version"

Gem::Specification.new do |spec|
  spec.name        = "restomatic"
  spec.version     = Restomatic::VERSION
  spec.authors     = ["Brad Gessler"]
  spec.email       = ["bradgessler@gmail.com"]
  spec.homepage    = "https://github.com/rocketshipio/restomatic"
  spec.summary     = "Better route mappers for Rails applications"
  spec.description = "Provides cleaner, more intuitive helpers for defining RESTful routes with proper scoping and namespacing in Rails"
  spec.license     = "MIT"
  
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 7.0"
  
  spec.required_ruby_version = ">= 3.0"
end