require 'base64'
require 'openssl'
require 'aws-sdk'
require 'kms_rails/configuration'

module KmsRails
  class Core
    def initialize(key_id:, context_key: nil, context_value: nil)
      @key_id = set_key_id(key_id)
      @context_key = context_key
      @context_value = context_value
    end

    def encrypt(data)
      return nil if data.nil?

      data_key = aws_generate_data_key(@key_id)
      encrypted = encrypt_attr(data, data_key.plaintext)

      self.class.shred_string(data_key.plaintext)
      data_key.plaintext = nil

      {
        'key' => data_key.ciphertext_blob,
        'iv' => encrypted[:iv],
        'blob' => encrypted[:data]
      }
    end

    def encrypt64(data)
      encrypt(data).map { |k,v| [k, Base64.strict_encode64(v)] }.to_h
    end

    def decrypt(data_obj)
      decrypt_attr(
        data_obj['blob'], 
        aws_decrypt_key(data_obj['key']),
        data_obj['iv']
      )
    end
    
    def decrypt64(data_obj)
      decrypt( data_obj.map { |k,v| [k, Base64.strict_decode64(v)] }.to_h )
    end

    def self.shred_string(str)
      str.force_encoding('BINARY')
      str.tr!("\0-\xff".b, "\0".b)
    end

    private 

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
      {iv: iv, data: cipher.update(data.to_s) + cipher.final}
    end

    def aws_decrypt_key(key)
      args = {ciphertext_blob: key}
      aws_kms.decrypt(apply_context(args, @context_key, @context_value)).plaintext
    end

    def aws_kms
      require 'kms_rails/kms_client_mock' if KmsRails.configuration.fake_kms_api == true
      @kms ||= Aws::KMS::Client.new
    end

    def aws_generate_data_key(key_id)
      args = {key_id: key_id, key_spec: 'AES_256'}
      aws_kms.generate_data_key(apply_context(args, @context_key, @context_value))
    end
  end
end