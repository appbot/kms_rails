Gem::Specification.new do |s|
  s.name = 'kms_attrs'
  s.version = '0.0.1'
  s.date = '2015-06-26'
  s.summary = 'AWS KMS encryption for ActiveRecord.'
  s.description = 'Quickly add KMS encryption and decryption to your ActiveRecord model attributes.'
  s.authors = ["Justin Ouellette"]
  s.email = 'ouellette.justin@gmail.com'
  s.files = ['lib/kms_attrs.rb']
  s.homepage = 'https://github.com/justinoue/kms_attrs'
  s.license = 'GPLv3'

  s.add_runtime_dependency 'activerecord'
  s.add_runtime_dependency 'aws-sdk', '~> 2'
  s.add_development_dependency 'rspec'
end
