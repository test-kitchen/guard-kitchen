# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'guard/kitchen/version'

Gem::Specification.new do |spec|
  spec.name          = "guard-kitchen"
  spec.version       = Guard::Kitchen::VERSION
  spec.authors       = ["Adam Jacob"]
  spec.email         = ["adam@opscode.com"]
  spec.description   = %q{Guard plugin for test kitchen}
  spec.summary       = %q{Guard plugin for test kitchen}
  spec.homepage      = "http://github.com/opscode/guard-kitchen"
  spec.license       = "Apache 2"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "guard"
  spec.add_dependency "mixlib-shellout"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
