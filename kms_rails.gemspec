# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kms_rails/version'

Gem::Specification.new do |spec|
  spec.name          = 'kms_rails'
  spec.version       = KmsRails::VERSION
  spec.authors       = ['Ash Tyndall', 'Justin Ouellette']
  spec.email         = ['ash@appbot.co']

  spec.summary       = %q{AWS KMS encryption for ActiveRecord & ActiveJob.}
  spec.description   = %q{Quickly add KMS encryption and decryption to your ActiveRecord model attributes and ActiveJob parameters. Improves upon kms_attrs with ActiveJob support, more efficient binary serialization and a test suite.}
  spec.homepage      = 'https://github.com/appbot/kms_rails'
  spec.license       = 'GPLv3'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5'

  spec.add_runtime_dependency 'activerecord', '>= 4'
  spec.add_runtime_dependency 'activejob', '>= 4'
  spec.add_runtime_dependency 'aws-sdk-kms', '~> 1'
  spec.add_runtime_dependency 'msgpack'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-mocks'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'with_model'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'database_cleaner'
end
