require 'msgpack'

module KmsAttrs
  class << self
    def included base
      base.extend ClassMethods
    end
  end
  
  module ClassMethods
    def kms_attr(field, key_id:, retain: false, context_key: nil, context_value: nil)
      include InstanceMethods

      real_field = "#{field}_enc"
      raise RuntimeError, "Field '#{real_field}' must exist to store encrypted data" unless self.column_names.include?(real_field)
      raise RuntimeError, "Field '#{field}' must not be a real column, '#{real_field}' is the real column" if self.column_names.include?(field)
      
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
          'key' => data_key.ciphertext_blob,
          'iv' => encrypted[:iv],
          'blob' => encrypted[:data]
        })
      end

      define_method "#{real_field}" do
        get_hash(field)
      end

      define_method "#{field}" do
        hash = get_hash(field)
        if hash
          if retain && plaintext = get_retained(field)
            plaintext
          else
            plaintext = decrypt_attr(
              hash['blob'], 
              aws_decrypt_key(hash['key'], context_key, context_value),
              hash['iv']
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

      define_method "#{field}_clear" do
        clear_retained(field)
      end

    end
  end

  module InstanceMethods
    def store_hash(field, data)
      @_hashes ||= {}
      serialized_data = data.to_msgpack
      @_hashes[field] = serialized_data
      self[:"#{field}_enc"] = serialized_data
    end

    def get_hash(field)
      @_hashes ||= {}
      hash = @_hashes[field] ||= read_attribute(:"#{field}_enc")
      if hash
        MessagePack.unpack(hash)
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

    def clear_retained(field)
      return unless @_retained.include? field
      @_retained[field].force_encoding('BINARY')
      @_retained[field].tr!("\0-\xff".b, "\0".b)
      @_retained[field] = nil
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
      @kms ||= Aws::KMS::Client.new
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
