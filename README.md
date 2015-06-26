#kms_attrs

kms_attrs is a gem for easily adding Amazon Web Services KMS encryption to your ActiveRecord model attributes. It uses the GenerateDataKey method to perform "envelope" encryption locally with an OpenSSL AES-256-CBC cipher.

To use, simply put the following code in your models for the fields you want to encrypt:
```
kms_attr :my_attribute, key_id: 'my-aws-kms-key-id'
```
Encryption is done at time of assignment.

To retrieve the decrypted data, call:
```
  my_model_instance.my_attribute_d
```

Encrypted data is stored as a hash in your database in the attribute column. It should be a text column as string may not be long enough.

##Additional Options
You can add encryption contexts as strings, method calls, or procs. Default is none.
```
kms_attr :my_attribute, key_id: 'my-aws-kms-key-id',
  context_key: 'my context key', context_value: 'my context value'

kms_attr :my_attribute, key_id: 'my-aws-kms-key-id',
  context_key: :model_method_context_key, context_value: :model_method_context_value

kms_attr :my_attribute, key_id: 'my-aws-kms-key-id',
  context_key: Proc.new { }, context_value: Proc.new { }
```

You can also toggle whether or not the model instance should retain decrypted values. Default is false. Change to true if you want to reduce the AWS API calls made for constant decryption. I cannot comment on the security implications enabling or disabling retaining.
```
kms_attr :my_attribute, key_id: 'my-aws-kms-key-id',
  retain: true
```

##Aws Configuration
This gem expects some standard Aws SDK configuration and some not so standard. The Aws client is initiated with no credentials. This should then load credentials either from ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY'] or an IAM role on an EC2 instance.

The not so standard configuration is specifiying ENV['AWS_DEFAULT_REGION'] for the AWS region you are using KMS in. KMS key IDs and operations are region specific. This will be moved to an overrideable initialization parameter. I forgot.

###Notes
This gem has been developed against Ruby 2.1.5, Rails 4.2, and AWS SDK v2.

###Disclaimer
I make no claims about enhanced security when using this gem.

###To Do
* Tests
* Choose your own encryption method
* Choose your own KMS key type

###Read more about AWS KMS
* http://aws.amazon.com/kms/
* http://docs.aws.amazon.com/sdkforruby/api/Aws/KMS/Client.html
