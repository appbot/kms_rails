require 'aws-sdk'
require 'msgpack'

module KmsRails
  module Aws
    module KMS
      class Client
        def generate_data_key(key_id:, key_spec:, encryption_context: nil)
          raise RuntimeError, 'Unsupported key_spec in test mode' unless key_spec == 'AES_256'

          plaintext = SecureRandom.random_bytes(256/8)

          ::Aws::KMS::Types::GenerateDataKeyResponse.new(
            key_id: key_id,
            plaintext: plaintext,
            ciphertext_blob: [key_id, encryption_context, plaintext].to_msgpack.reverse,
          )
        end

        def decrypt(ciphertext_blob:, encryption_context: nil)
          key_id, decoded_context, plaintext = MessagePack.unpack(ciphertext_blob.reverse)
          raise ::Aws::KMS::Errors::InvalidCiphertextException.new(nil, nil) unless decoded_context == encryption_context

          ::Aws::KMS::Types::DecryptResponse.new(
            key_id: key_id,
            plaintext: plaintext,
          )
        rescue MessagePack::MalformedFormatError
          raise ::Aws::KMS::Errors::InvalidCiphertextException.new(nil, nil)
        end

        def inspect
          "#<Aws::KMS::Client (mocked)>"
        end
      end
    end
  end
end
