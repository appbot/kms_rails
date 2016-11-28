require 'support/test_job'

describe KmsRails::ActiveJob do
  context 'serialization' do
    context '::kms_arg' do
      subject { FirstArgEncryptedJob }

      it 'calls the encryption routine once' do
        expect_any_instance_of(KmsRails::Aws::KMS::Client).to receive(:generate_data_key)
          .once
          .with(hash_including(key_id: 'q', key_spec: 'AES_256'))
          .and_call_original

        subject.new('foo', 'bar', 'baz').serialize
      end

      it 'produces an encrypted argument' do
        serialized = subject.new('foo', 'bar', 'baz').serialize['arguments']

        expect(serialized.length).to eq(3)
        expect(serialized[0].keys).to include('key', 'iv', 'blob')
        expect(serialized[1]).to eq('bar')
        expect(serialized[2]).to eq('baz')  
      end
    end

    context '::kms_args' do
      subject { SecondThirdArgEncryptedJob }

      it 'calls the encryption routine twice' do
        expect_any_instance_of(KmsRails::Aws::KMS::Client).to receive(:generate_data_key)
          .twice
          .with(hash_including(key_id: 'r', key_spec: 'AES_256'))
          .and_call_original

        subject.new('foo', 'bar', 'baz').serialize
      end

      it 'produces an encrypted argument' do
        serialized = subject.new('foo', 'bar', 'baz').serialize['arguments']

        expect(serialized.length).to eq(3)
        expect(serialized[0]).to eq('foo')
        expect(serialized[1].keys).to include('key', 'iv', 'blob')
        expect(serialized[2].keys).to include('key', 'iv', 'blob')
      end
    end

  end


  context 'deserialization' do
    context '1 argument' do 
      let(:serialized) { {
        'job_class'=>'FirstArgEncryptedJob',
        'job_id'=>'39413211-1db3-41d6-92c3-68500713061f',
        'queue_name'=>'default',
        'arguments'=>
          [{'key'=>'JXosoJ55meLuaURZzVjqf8JNrMQHE+MhAgGm9WAgPKEgxMBxoZM=',
            'iv'=>'/NfACho6+aNyRQzZxFdpdg==',
            'blob'=>'gYiFaMUIqgjhJOSQfuJGeA==',
            '_aj_symbol_keys'=>[]},
           'bar',
           'baz'],
        'locale'=>:en
      } }

      subject { FirstArgEncryptedJob }

      it 'deserializes and decrypts arguments' do
        job = subject.deserialize(serialized)
        expect(job.perform_now).to eq(['baz', 'bar', 'foo'])
      end
    end

    context 'multiple arguments' do
      let(:serialized) { {
        'job_class'=>'SecondThirdArgEncryptedJob',
        'job_id'=>'f3fdc797-6150-40b4-a296-e25b709a3117',
        'queue_name'=>'default',
        'arguments'=>
          ['foo',
           {'key'=>'/yI5gBrOiS4shhtSj53LCv2Uwl787PQ4X/rnMfBDX7sgxMByoZM=',
            'iv'=>'jTLJuiS5EwocCD6v1U/3Ww==',
            'blob'=>'xNfbNyVuuMz27Y56yU9OOw==',
            '_aj_symbol_keys'=>[]},
           {'key'=>'OjoiEIbYjF+d2b4itx/ll1gOC5Ycn+TZg6cOttJeNe8gxMByoZM=',
            'iv'=>'SLPKya28OqC1QKnuhTPfLQ==',
            'blob'=>'Cx0jdSWP2qKH8MhtIp7Mnw==',
            '_aj_symbol_keys'=>[]}],
        'locale'=>:en
      } }

      subject { SecondThirdArgEncryptedJob }

      it 'deserializes and decrypts arguments' do
        job = subject.deserialize(serialized)
        expect(job.perform_now).to eq(['baz', 'bar', 'foo'])
      end
    end
  end
end
