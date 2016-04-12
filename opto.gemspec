# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'opto/version'

Gem::Specification.new do |spec|
  spec.name          = "opto"
  spec.version       = '0.1.0'
  spec.authors       = ["Dan Milne"]
  spec.email         = ["d@nmilne.com"]

  spec.summary       = %q{Server Testing}
  spec.description   = %q{Runs various tests against your webserver}
  spec.homepage      = "https://github.com/dkam/opto/wiki"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = ['opto']
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_runtime_dependency     'addressable', '~> 2.3'
  spec.add_runtime_dependency     'nokogiri', '~> 1.6'
  spec.add_runtime_dependency     'colorize', '~> 0.7'
  spec.add_runtime_dependency     'fastimage', '~> 1.7'
  spec.add_runtime_dependency     'httpclient', '~> 2.7'
end
