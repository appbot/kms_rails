module Aws
  module KMSMocked
    class Client
      def initialize
        @@blob_to_key = {}
      end

      def generate_data_key(key_id:, key_spec:, encryption_context: nil)
        raise RuntimeError, 'Unsupported key_spec in test mode' unless key_spec == 'AES_256'

        plaintext = SecureRandom.random_bytes(256/8)
        ciphertext_blob = plaintext.reverse
        @@blob_to_key[ciphertext_blob] = key_id

        Aws::KMS::Types::GenerateDataKeyResponse.new(
          key_id: key_id,
          plaintext: plaintext,
          ciphertext_blob: ciphertext_blob,
        )
      end

      def decrypt(ciphertext_blob:, encryption_context: nil)
        raise Aws::KMS::Errors::InvalidCiphertextException.new(nil, nil) unless @@blob_to_key.include?(ciphertext_blob)

        Aws::KMS::Types::DecryptResponse.new(
          key_id: @@blob_to_key[ciphertext_blob],
          plaintext: ciphertext_blob.reverse,
        )
      end

      def inspect
        "#<Aws::KMS::Client:#{self.object_id}>"
      end
    end
  end
end