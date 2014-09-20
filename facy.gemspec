# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'facy/version'

Gem::Specification.new do |spec|
  spec.name          = "facy"
  spec.version       = Facy::VERSION
  spec.authors       = ["dxhuy1988"]
  spec.email         = ["doxuanhuy@gmail.com"]
  spec.summary       = %q{facy: terminal client for facebook}
  spec.description   = %q{facy: first colorful terminal client for facebook}
  spec.homepage      = "https://github.com/huydx/facy"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split("\n") + ['config.yml']
  spec.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '>= 1.9.3'

  spec.add_runtime_dependency "bundler", "~> 1.5"
  spec.add_runtime_dependency "koala", "~>1.10"
  spec.add_runtime_dependency "activesupport", "~>4.0"
  spec.add_runtime_dependency "launchy", "~>2.4"
  spec.add_runtime_dependency "eventmachine", "~>1.0"
end
