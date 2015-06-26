module KmsAttrs
  class << self
    def included base
      base.extend ClassMethods
    end
  end
  
  module ClassMethods
    def kms_attr(field, key_id:, retain: false, context_key: nil, context_value: nil)
      include InstanceMethods
      
      define_method "#{field}=" do |data|
        key_id = set_key_id(key_id)
        data_key = aws_generate_data_key(key_id, context_key, context_value)
        encrypted = encrypt_attr(data, data_key.plaintext)
        data_key.plaintext = nil

        if retain
          set_retained(field, data)  
        end
        data = nil
        
        store_hash(field, {
          key: data_key.ciphertext_blob,
          iv: encrypted[:iv],
          blob: encrypted[:data]
        })
      end

      define_method "#{field}" do
        get_hash(field)
      end

      define_method "#{field}_d" do
        hash = get_hash(field)
        if hash
          if retain && plaintext = get_retained(field)
            plaintext
          else
            plaintext = decrypt_attr(
              hash[:blob], 
              aws_decrypt_key(hash[:key], context_key, context_value),
              hash[:iv]
            )

            if retain
              set_retained(field, plaintext)
            end

            plaintext
          end
        else
          nil
        end
      end

    end
  end

  module InstanceMethods
    def store_hash(field, data)
      @_hashes ||= {}
      b_data = Marshal.dump(data)
      data64 = Base64.encode64(b_data)
      @_hashes[field] = data64
      self[field] = data64
    end

    def get_hash(field)
      @_hashes ||= {}
      hash = @_hashes[field] ||= read_attribute(field)
      if hash
        Marshal.load(Base64.decode64(hash))
      else
        nil
      end
    end

    def get_retained(field)
      @_retained ||= {}
      @_retained[field]
    end

    def set_retained(field, plaintext)
      @_retained ||= {}
      @_retained[field] = plaintext
    end

    def decrypt_attr(data, key, iv)
      decipher = OpenSSL::Cipher.new('AES-256-CBC')
      decipher.decrypt
      decipher.key = key
      decipher.iv = iv
      decipher.update(data) + decipher.final
    end

    def encrypt_attr(data, key)
      cipher = OpenSSL::Cipher.new('AES-256-CBC')
      cipher.encrypt

      cipher.key = key
      iv = cipher.random_iv
      {iv: iv, data: cipher.update(data) + cipher.final}
    end

    def aws_decrypt_key(key, context_key, context_value)
      args = {ciphertext_blob: key}
      aws_kms.decrypt(apply_context(args, context_key, context_value)).plaintext
    end

    def aws_kms
      @kms ||= Aws::KMS::Client.new(region: ENV['AWS_DEFAULT_REGION'])
    end

    def aws_generate_data_key(key_id, context_key, context_value)
      args = {key_id: key_id, key_spec: 'AES_256'}
      aws_kms.generate_data_key(apply_context(args, context_key, context_value))
    end

    def apply_context(args, key, value)
      if key && value
        if key.is_a?(Proc)
          key = key.call
        end

        if value.is_a?(Proc)
          value = value.call
        end

        if key.is_a?(Symbol)
          key = self.send(key)
        end

        if value.is_a?(Symbol)
          value = self.send(value)
        end

        if key.is_a?(String) && value.is_a?(String)
          args[:encryption_context] = {key => value}
        end
      end
      args
    end

    def set_key_id(key_id)
      if key_id.is_a?(Proc)
        key_id = key_id.call
      end

      if key_id.is_a?(Symbol)
        key_id = self.send(key_id)
      end

      if key_id.is_a?(String)
        return key_id
      end
    end
  end
end

if Object.const_defined?('ActiveRecord')
  ActiveRecord::Base.send(:include, KmsAttrs)
end
