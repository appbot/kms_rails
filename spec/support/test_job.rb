class FirstArgEncryptedJob < ActiveJob::Base
  kms_arg 0, key_id: 'q'

  def perform(arg1, arg2, arg3) 
    [arg3, arg2, arg1]
  end
end

class SecondThirdArgEncryptedJob < ActiveJob::Base
  kms_args [1,2], key_id: 'r'

  def perform(arg1, arg2, arg3) 
    [arg3, arg2, arg1]
  end
end
