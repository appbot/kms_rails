require 'support/test_job'

describe KmsRails::ActiveJob do
  context 'serialization' do
    context '::kms_arg' do
      subject { FirstArgEncryptedJob }

      it 'calls the encryption routine once' do
        expect(KmsRails.configuration.kms_client).to receive(:generate_data_key)
          .once
          .with(hash_including(key_id: 'alias/q', key_spec: 'AES_256'))
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

      it 'doesn\'t double encrypt an already encrypted value' do
        expect(KmsRails.configuration.kms_client).to_not receive(:generate_data_key)

        subject.new(
          {'key' => 'YmF6', 'iv' => 'Zm9v', 'blob' => 'YmFy'},
          'bar',
          'baz'
          ).serialize
      end

      it 'doesn\'t encrypt nil' do
        expect(KmsRails.configuration.kms_client).to_not receive(:generate_data_key)

        subject.new(
          nil,
          'bar',
          'baz'
          ).serialize
      end
    end

    context '::kms_args' do
      subject { SecondThirdArgEncryptedJob }

      it 'calls the encryption routine twice' do
        expect(KmsRails.configuration.kms_client).to receive(:generate_data_key)
          .twice
          .with(hash_including(key_id: 'alias/r', key_spec: 'AES_256'))
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

    context 'msgpack enabled' do
      context '::kms_arg' do
        subject { FirstArgMsgPackEncryptedJob }

        it 'calls the encryption routine once' do
          expect(KmsRails.configuration.kms_client).to receive(:generate_data_key)
            .once
            .with(hash_including(key_id: 'alias/s', key_spec: 'AES_256'))
            .and_call_original

          subject.new({'a' => 'b', 'c' => 'd'}, 'bar', 'baz').serialize
        end

        it 'produces an encrypted argument' do
          serialized = subject.new({'a' => 'b', 'c' => 'd'}, 'bar', 'baz').serialize['arguments']

          expect(serialized.length).to eq(3)
          expect(serialized[0].keys).to include('key', 'iv', 'blob')
          expect(serialized[1]).to eq('bar')
          expect(serialized[2]).to eq('baz')  
        end
      end

      context '::kms_args' do
        subject { SecondThirdArgMsgPackEncryptedJob }

        it 'calls the encryption routine twice' do
          expect(KmsRails.configuration.kms_client).to receive(:generate_data_key)
            .twice
            .with(hash_including(key_id: 'alias/t', key_spec: 'AES_256'))
            .and_call_original

          subject.new('foo', {'a' => 'b', 'c' => 'd'}, {'q' => 'r', 's' => 't'}).serialize
        end

        it 'produces an encrypted argument' do
          serialized = subject.new('foo', {'a' => 'b', 'c' => 'd'}, {'q' => 'r', 's' => 't'}).serialize['arguments']

          expect(serialized.length).to eq(3)
          expect(serialized[0]).to eq('foo')
          expect(serialized[1].keys).to include('key', 'iv', 'blob')
          expect(serialized[2].keys).to include('key', 'iv', 'blob')
        end
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

    context 'msgpack enabled' do
      let(:serialized) { {
        'job_class'=>'FirstArgMsgPackEncryptedJob',
        'job_id'=>'39413211-1db3-41d6-92c3-68500713061f',
        'queue_name'=>'default',
        'arguments'=>
          [{'key'=>'NcWpobONtzmHoe7G2wH7v3fcgdqUbYUPehGXuHq5q0cgxMBzL3NhaWxhp5M=',
            'iv'=>'r2ZIjyxAs3ZZAlLOdOFqdg==',
            'blob'=>'Pif4qYHilkRiupLljJAyng==',
            '_aj_symbol_keys'=>[]},
           'bar',
           'baz'],
        'locale'=>:en
      } }

      subject { FirstArgMsgPackEncryptedJob }

      it 'deserializes and decrypts arguments' do
        job = subject.deserialize(serialized)
        expect(job.perform_now).to eq(['baz', 'bar', {'a' => 'b', 'c' => 'd'}])
      end
    end

    context 'msgpack enabled' do
      let(:serialized) { {
        'job_class'=>'SecondThirdArgMsgPackEncryptedJob',
        'job_id'=>'84614af7-bfd9-4628-a45c-952fe668daa9',
        'queue_name'=>'default',
        'arguments'=>
          ['foo',
           {'key'=>'x4TjhPNHr/ldfG1uauYy5ouyXAWqtGmT9N3ppG/DjBkgxMB0L3NhaWxhp5M=',
            'iv'=>'2n7Eilu3B4X/8EE/fs+4RQ==',
            'blob'=>'zQg4Ajsdd+eL/N+Uipl4eQ==',
            '_aj_symbol_keys'=>[]},
           {'key'=>'U5wDfi4xc78qQD9mPcvrOhbD5ZQyxlTX3dSoPiMgTNUgxMB0L3NhaWxhp5M=',
            'iv'=>'LOElUyDv2l1l9WgLY5/few==',
            'blob'=>'n1XRnrjxvBynuVU5pbQK5g==',
            '_aj_symbol_keys'=>[]}],
        'locale'=>:en
      } }

      subject { SecondThirdArgMsgPackEncryptedJob }

      it 'deserializes and decrypts arguments' do
        job = subject.deserialize(serialized)
        expect(job.perform_now).to eq([{'q' => 'r', 's' => 't'}, {'a' => 'b', 'c' => 'd'}, 'foo'])
      end
    end
  end
end
