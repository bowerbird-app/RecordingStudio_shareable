# frozen_string_literal: true

require_relative "lib/recording_studio_shareable/version"

Gem::Specification.new do |spec|
  spec.name        = "recording_studio_shareable"
  spec.version     = RecordingStudioShareable::VERSION
  spec.authors     = ["Bowerbird"]
  spec.homepage    = "https://github.com/bowerbird-app/recording_studio_shareable"
  spec.summary     = "Opt-in public sharing for Recording Studio recordables"
  spec.description = "Resolves an absolute public share URL, social destination links, and " \
                     "social preview tags for recordables that opt into Shareable. " \
                     "Publishable decides publication. Shareable only distributes an eligible URL."
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bowerbird-app/recording_studio_shareable"
  spec.metadata["changelog_uri"] = "https://github.com/bowerbird-app/recording_studio_shareable/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"].reject do |path|
      path == ".cursor" || path.start_with?(".cursor/")
    end
  end

  spec.add_dependency "rails", "~> 8.1.0"
  spec.add_dependency "recording_studio", "~> 4.2"
  spec.add_dependency "view_component", ">= 4.14", "< 5"
end
