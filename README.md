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
