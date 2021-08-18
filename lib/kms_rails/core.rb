require 'base64'
require 'openssl'
require 'msgpack'
require 'aws-sdk-kms'
require 'kms_rails/configuration'

module KmsRails
  class Core
    attr_reader :context_key, :context_value

    def initialize(key_id:, msgpack: false, context_key: nil, context_value: nil)
      @base_key_id = key_id
      @context_key = context_key
      @context_value = context_value
      @msgpack = msgpack
    end

    def encrypt(data)
      return nil if data.nil?

      data_key = aws_generate_data_key(key_id)
      data = data.to_msgpack if @msgpack
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
      return nil if data.nil?
      self.class.to64(encrypt(data))
    end

    def decrypt(data_obj)
      return nil if data_obj.nil?

      decrypted = decrypt_attr(
        data_obj['blob'],
        aws_decrypt_key(data_obj['key']),
        data_obj['iv']
      )

      decrypted = MessagePack.unpack(decrypted) if @msgpack
      decrypted
    end

    def decrypt64(data_obj)
      return nil if data_obj.nil?
      decrypt( self.class.from64(data_obj) )
    end

    def key_id
      case @base_key_id
      when Proc
        @base_key_id.call
      when String
        if @base_key_id =~ /\A\w{8}-\w{4}-\w{4}-\w{4}-\w{12}\z/ || @base_key_id.start_with?('alias/') # if UUID or direct alias
          KmsRails.configuration.arn_prefix + @base_key_id
        else
          KmsRails.configuration.arn_prefix + 'alias/' + KmsRails.configuration.alias_prefix + @base_key_id
        end
      else
        raise RuntimeError, 'Only Proc and String arguments are supported'
      end
    end

    def self.shred_string(str)
      str.force_encoding('BINARY')
      str.tr!("\0-\xff".b, "\0".b)
    end

    def self.to64(data_obj)
      return nil if data_obj.nil?
      data_obj.map { |k,v| [k, Base64.strict_encode64(v)] }.to_h
    end

    def self.from64(data_obj)
      return nil if data_obj.nil?
      data_obj.map { |k,v| [k, Base64.strict_decode64(v)] }.to_h
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

        if key.is_a?(String) && value.is_a?(String)
          args[:encryption_context] = {key => value}
        end
      end
      args
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
      aws_kms.decrypt(**apply_context(args, @context_key, @context_value)).plaintext
    end

    def aws_kms
      KmsRails.configuration.kms_client ||
        (@aws_kms ||= Aws::KMS::Client.new)
    end

    def aws_generate_data_key(key_id)
      args = {key_id: key_id, key_spec: 'AES_256'}
      aws_kms.generate_data_key(**apply_context(args, @context_key, @context_value))
    end
  end
end
