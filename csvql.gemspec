# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'csvql/version'

Gem::Specification.new do |spec|
  spec.name          = "csvql"
  spec.version       = Csvql::VERSION
  spec.authors       = ["YANO Satoru"]
  spec.email         = ["s-yano@pb.jp.nec.com"]
  spec.summary       = %q{csvql}
  spec.description   = ""
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # spec.add_development_dependency "bundler", "~> 1.6"
  # spec.add_development_dependency "rake"
  # spec.add_development_dependency "rspec"
  # spec.add_development_dependency "pry"
  # spec.add_development_dependency "minitest"
  spec.add_runtime_dependency "sqlite3"
end
