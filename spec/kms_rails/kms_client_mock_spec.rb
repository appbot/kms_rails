describe KmsRails::Aws::KMS::Client do
  subject { KmsRails::Aws::KMS::Client.new }

  it 'encrypts and decrypts a string correct' do
    data_key = subject.generate_data_key(key_id: 'a', key_spec: 'AES_256')
    decrypted = subject.decrypt(ciphertext_blob: data_key.ciphertext_blob)

    expect(decrypted.key_id).to eq('a')
    expect(decrypted.plaintext).to eq(data_key.plaintext)
  end

  it 'raises error when decrypting malformed text' do
    expect {
      subject.decrypt(ciphertext_blob: 't8hvosdjdlqegohqevnsLCKsz')
    }.to raise_error(::Aws::KMS::Errors::InvalidCiphertextException)
  end

  it 'allows inspect' do
    expect {
      subject.inspect
    }.to_not raise_error
  end

  context 'encryption context' do
    it 'works successfully with correct' do
      data_key = subject.generate_data_key(key_id: 'a', key_spec: 'AES_256', encryption_context: {'foo' => 'bar'})
      decrypted = subject.decrypt(ciphertext_blob: data_key.ciphertext_blob, encryption_context: {'foo' => 'bar'})
      
      expect(decrypted.key_id).to eq('a')
      expect(decrypted.plaintext).to eq(data_key.plaintext)
    end

    it 'fails with mismatched' do
      data_key = subject.generate_data_key(key_id: 'a', key_spec: 'AES_256', encryption_context: {'foo' => 'bar'})
      
      expect { 
        subject.decrypt(ciphertext_blob: data_key.ciphertext_blob, encryption_context: {'foo' => 'norp'})
      }.to raise_error(::Aws::KMS::Errors::InvalidCiphertextException)
    end

    it 'fails with undeclared generate' do
      data_key = subject.generate_data_key(key_id: 'a', key_spec: 'AES_256')
      
      expect { 
        subject.decrypt(ciphertext_blob: data_key.ciphertext_blob, encryption_context: {'foo' => 'norp'})
      }.to raise_error(::Aws::KMS::Errors::InvalidCiphertextException)
    end

    it 'fails with undeclared decrpt' do
      data_key = subject.generate_data_key(key_id: 'a', key_spec: 'AES_256', encryption_context: {'foo' => 'bar'})
      
      expect { 
        subject.decrypt(ciphertext_blob: data_key.ciphertext_blob)
      }.to raise_error(::Aws::KMS::Errors::InvalidCiphertextException)
    end
  end
end
