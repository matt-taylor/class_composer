# frozen_string_literal: true

require_relative "lib/class_composer/version"

Gem::Specification.new do |spec|
  spec.name    = "class_composer"
  spec.version = ClassComposer::VERSION
  spec.authors = ["Matt Taylor"]
  spec.email   = ["mattius.taylor@gmail.com"]

  spec.summary     = "Easily compose a class via inline code or passed in YAML config. Add instance attributes with custom validations that will DRY up your code"
  spec.description = "Compose configurations for any class."
  spec.homepage    = "https://github.com/matt-taylor/class_composer"
  spec.license     = "MIT"

  spec.required_ruby_version = Gem::Requirement.new(">= 3.1")

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]
end
