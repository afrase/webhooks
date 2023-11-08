# frozen_string_literal: true

require_relative "lib/webhooks/version"

Gem::Specification.new do |spec|
  spec.name = "webhooks"
  spec.version = Webhooks::VERSION
  spec.authors = ["Aaron Frase"]
  spec.email = ["afrase91@gmail.com"]

  spec.summary = "Gem for ingesting webhooks"
  spec.description = "Gem for ingesting webhooks"
  spec.homepage = "https://github.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = ""
  # spec.metadata["changelog_uri"] = ""

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency("activesupport", "~> 7.0")
  spec.add_runtime_dependency("dry-configurable", "~> 1.1")

  spec.add_development_dependency("pry", "~> 0.14.2")
  spec.add_development_dependency("rake", "~> 13.0")
  spec.add_development_dependency("rspec", "~> 3.0")
  spec.add_development_dependency("rubocop", "~> 1.56")
  spec.add_development_dependency("rubocop-performance", "~> 1.19")
  spec.add_development_dependency("rubocop-rspec", "~> 2.23", ">= 2.23.2")
end
