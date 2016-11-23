Gem::Specification.new do |s|
  s.name = 'kms_attrs2'
  s.version = '0.0.2'
  s.summary = 'AWS KMS encryption for ActiveRecord.'
  s.description = 'Quickly add KMS encryption and decryption to your ActiveRecord model attributes.'
  s.authors = ["Ash Tyndall", "Justin Ouellette"]
  s.email = 'ash@appbot.co'
  s.files = ['lib/kms_attrs.rb']
  s.homepage = 'https://github.com/appbotx/kms_attrs2'
  s.license = 'GPLv3'

  s.add_runtime_dependency 'activerecord'
  s.add_runtime_dependency 'aws-sdk-resources', '~> 2'
  s.add_runtime_dependency 'msgpack'
  s.add_development_dependency 'rspec'
end
