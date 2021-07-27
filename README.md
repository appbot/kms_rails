[![Build Status](https://travis-ci.org/appbot/kms_rails.svg)](https://travis-ci.org/appbot/kms_rails)
[![Code Climate](https://codeclimate.com/github/appbot/kms_rails/badges/gpa.svg)](https://codeclimate.com/github/appbot/kms_rails) [![Test Coverage](https://codeclimate.com/github/appbot/kms_rails/badges/coverage.svg)](https://codeclimate.com/github/appbot/kms_rails/coverage)

# kms_rails

kms_rails (based on [kms_attrs](https://github.com/justinoue/kms_attrs)) is a gem for easily adding Amazon Web Services KMS encryption to your ActiveRecord model attributes and ActiveJob arguments. It uses the GenerateDataKey method to perform "envelope" encryption locally with an OpenSSL AES-256-CBC cipher.

It improves upon kms_attrs by adding support for ActiveJob argument encryption, moving to a more efficient serialization model and introducing a fairly comprehensive test suite.

## Getting started

Add this line to your application's Gemfile:

```ruby
gem 'kms_rails'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kms_rails

## ActiveRecord

To use on ActiveRecord, simply put the following code in your models for the fields you want to encrypt:
```ruby
kms_attr :my_attribute, key_id: 'my-aws-kms-key-id'
```
Encryption is done at time of assignment and is stored in the real database field 'my_attribute_enc'.

To retrieve the decrypted data, call:
```ruby
  my_model_instance.my_attribute
```

Encrypted data is stored as a [MessagePack](https://github.com/msgpack/msgpack-ruby) blob in your database in the `#{my_attribute}_enc` column. It should be a binary column of sufficient size to store the encrypted data + metadata (suggested 65535).

You can also toggle whether or not the model instance should retain decrypted values. Default is false. Change to true if you want to reduce the AWS API calls made for constant decryption. The security implications of enabling or disabling retaining are not commented upon.
```ruby
kms_attr :my_attribute, key_id: 'my-aws-kms-key-id',
  retain: true
```

To clear a retained decrypted value, call:
```ruby
  my_model_instance.my_attribute_clear
```

This will attempt mutate the stored string to contain just null bytes, and then dereference it to be garbage collected. No guarantees are provided about additional copies of the retained data being cached elsewhere.

### Data Serialization

By default kms_rails will convert your encrypted values into strings, however if you would like higher level structures to be stored, you can set `msgpack: true` on any kms_attr declaration. This will encode and decode your values using [MessagePack](https://github.com/msgpack/msgpack-ruby), as long as those value types are supported by it.

## ActiveJob

To use on ActiveJob, simply put the following code in your job for the arguments you wish to encrypt in flight.
```ruby
kms_arg 0, key_id: 'my-aws-kms-key-id'
kms_args [0, 1], key_id: 'my-aws-kms-key-id'

# The below sample will ensure param1 is encrypted before entering the job store
class TestJob < ActiveJob::Base
  kms_arg 0, key_id: 'my-aws-kms-key-id'

  def perform(param1, param2)
    # Do things
  end
end
```

Note: You can only declare kms_arg/kms_args once. Use kms_args if you want to encrypt multiple arguments. Seperate keys per argument are not implemented at this time.

Encryption is done when the job is seralized into the data store and is stored as a JSON hash of the necessary encyption information.

The encryption is automatically reversed when the job is deserialized.

### Data Serialization

Like kms_attr above, by default your encrypted kms_args values are converted to and from strings. Similarly, you can set `msgpack: true` to enable msgpack serialization and deserialization for arguments instead.

### Already encrypted parameters

You also have the option of passing the value from your ActiveRecord encrypted field directly into the ActiveJob. If you do this, the value will not be encrypted twice. However, if you do this, you must ensure that the encryption key ID is the same for both the ActiveRecord attribute and ActiveJob parameter. It is also wise to use the same `msgpack: ` configuration options for both instances to ensure it is correctly decoded.

For instance, if you want to enqueue an encrypted value into a job on a node that cannot decrypt that value, you could do something like this;

```ruby
value = MyModel.find(10).secret_field_enc
MyImportantJob.perform_later(value)
```

In this instance, `value` will not be decrypted, nor encrypted twice.

## Additional Options
You can add encryption contexts as strings or procs to kms_attr and kms_arg/args. Default is none.
```ruby
kms_attr :my_attribute, key_id: 'my-aws-kms-key-id',
  context_key: 'my context key', context_value: 'my context value'

kms_attr :my_attribute, key_id: 'my-aws-kms-key-id',
  context_key: Proc.new { }, context_value: Proc.new { }
```

## Aws Configuration
This gem expects some standard Aws SDK configuration. The Aws client is initiated with no credentials. This should then load credentials either from ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'], `Aws` object, or an IAM role on an EC2 instance.

You can configure your region in a Rails initializer with;
```ruby
Aws.config[:region] = 'us-east-1'
```

or by using the documented AWS environmental variables.

## Test Mode

A basic fake implementation of `Aws::KMS::Client` has been written, allowing kms_rails functionality to be used in test environments without making any web requests. The fake implementation emulates the functionality of the two API calls kms_rails issues to AWS and performs fake encryption (the key is 'encrypted' by reversing it).

You can enable it in your Rails initializers with the following
```ruby
KmsRails.configure do |config|
  config.fake_kms_api = true
end
```

## Alias prefixes

You can use the `alias_prefix` configuration option to automatically add a prefix to the key_ids that you specify. For example;

```ruby
KmsRails.configure do |config|
  config.alias_prefix = Rails.env + '/'
end

kms_attr :my_attribute, key_id: 'my-key-alias'
```

Will resolve 'my-key-alias' to 'alias/production/my-key-alias' in the production environment, and 'alias/staging/my-key-alias' in staging.

Directly specifying a key_id as a UUID or with the `alias/` prefix explicitly declared will prevent this behaviour from occurring.

## ARN prefixes

You can use the `arn_prefix` configuration option to specify that the keys you're referencing are located in a different AWS account or region than the default. For example;

```ruby
KmsRails.configure do |config|
  config.arn_prefix = 'arn:aws:kms:ap-southeast-1:11111111111:'
end

kms_attr :my_attribute, key_id: 'my-key-alias'
```

Will resolve 'my-key-alias' to 'arn:aws:kms:ap-southeast-1:11111111111:alias/my-key-alias', which may be a key in a different region or AWS account.

This works for aliases and UUID keys, but Proc based key_ids will not have the ARN prefixed.

You can use this in combination with alias prefixes. A prefix like 'foo/' would result in a final key of 'arn:aws:kms:ap-southeast-1:11111111111:alias/foo/my-key-alias'.

## Other stuff

### Notes
This gem has been developed against Ruby 2.3.1, Rails 4.2, and AWS SDK v3. Credit where credit is due, strongbox by spikex was used as an inspiration and guide when creating this. https://github.com/spikex/strongbox

### Disclaimer
No claims are made about enhanced security when using this gem.

### Read more about AWS KMS
* http://aws.amazon.com/kms/
* http://docs.aws.amazon.com/sdkforruby/api/Aws/KMS/Client.html

### Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

### Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/appbot/kms_rails.
