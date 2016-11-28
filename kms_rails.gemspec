Gem::Specification.new do |s|
  s.name = 'kms_rails'
  s.version = '0.0.1'
  s.summary = 'AWS KMS encryption for ActiveRecord & ActiveJob.'
  s.description = 'Quickly add KMS encryption and decryption to your ActiveRecord model attributes and ActiveJob parameters.'
  s.authors = ["Ash Tyndall", "Justin Ouellette"]
  s.email = 'ash@appbot.co'
  s.files = ['lib/*']
  s.homepage = 'https://github.com/appbot/kms_rails'
  s.license = 'GPLv3'
  s.require_paths = ['lib']

  s.add_runtime_dependency 'activerecord'
  s.add_runtime_dependency 'activejob'
  s.add_runtime_dependency 'aws-sdk', '~> 2'
  s.add_runtime_dependency 'msgpack'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rspec-mocks'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'with_model'
  s.add_development_dependency 'byebug'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'database_cleaner'
end
