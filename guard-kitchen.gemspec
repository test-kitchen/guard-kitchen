# coding: utf-8
# Read the version without loading the library: version.rb requires guard,
# which is not available while bundler is evaluating this gemspec.
version = File.read(File.expand_path('lib/guard/kitchen/version.rb', __dir__))[/VERSION\s*=\s*["']([^"']+)["']/, 1]

Gem::Specification.new do |spec|
  spec.name          = "guard-kitchen"
  spec.required_ruby_version = ">= 3.1"
  spec.version       = version
  spec.authors       = ["Adam Jacob"]
  spec.email         = ["adam@chef.io"]
  spec.description   = %q{Guard plugin for test kitchen}
  spec.summary       = %q{Guard plugin for test kitchen}
  spec.homepage      = "http://github.com/test-kitchen/guard-kitchen"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "guard", "> 2.0.0"
  spec.add_dependency "mixlib-shellout"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
