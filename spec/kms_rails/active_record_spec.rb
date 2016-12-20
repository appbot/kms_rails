describe KmsRails::ActiveRecord do

  with_model :NormalModelNoRetain do
    table do |t|
      t.string :secret_name
      t.binary :the_secret_enc
      t.timestamps null: false
    end

    model do
      kms_attr :the_secret, key_id: 'a', retain: false
    end
  end

  with_model :NormalModelRetain do
    table do |t|
      t.string :secret_name
      t.binary :the_secret_enc
      t.timestamps null: false
    end

    model do
      kms_attr :the_secret, key_id: 'a', retain: true
    end
  end

  with_model :NormalModelMsgPack do
    table do |t|
      t.string :secret_name
      t.binary :the_secret_enc
      t.timestamps null: false
    end

    model do
      kms_attr :the_secret, key_id: 'a', msgpack: true
    end
  end

  context '::kms_attr' do
    let(:model) { NormalModelNoRetain }
    subject { model.kms_attr :the_secret, key_id: 'a' }

    it 'defines the_secret fields' do
      expect(model.instance_methods).to include(
        :the_secret, :the_secret=, :the_secret_enc, :the_secret_clear
      )
    end

    context '_enc field doens\'t exist' do 
      let (:model) { NoEncModel }

      with_model :NoEncModel do
        table do |t|
          t.string :secret_name
        end
      end

      it 'throws an exception' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end

    context 'real field exists' do
      let (:model) { RealFieldModel }

      with_model :RealFieldModel do
        table do |t|
          t.string :secret_name
          t.binary :the_secret
        end
      end

      it 'throws an exception' do
        expect { subject }.to raise_error(RuntimeError)
      end
    end
  end

  context 'data storage' do
    let(:model) { NormalModelNoRetain }
    subject { model.new }

    let(:data) { {'foo' => 'bar', 'baz' => 'boo'} }
    let(:packed_data) { "\x82\xA3foo\xA3bar\xA3baz\xA3boo".b } 

    context '#store_hash' do
      it 'converts data to messagepack and stores' do
        subject.store_hash('the_secret', data)
        expect( subject['the_secret_enc'] ).to eq(packed_data)
      end
    end

    context '#get_hash' do
      it 'converts data from messagepack and returns' do
        subject['the_secret_enc'] = packed_data
        expect( subject.get_hash('the_secret') ).to eq(data)
      end
    end
  end

  context 'retention' do
    let(:model) { NormalModelNoRetain }
    subject { model.new }

    context '#get_retained / #set_retained' do
      it 'returns nothing if nothing has been retained' do
        expect( subject.get_retained('the_secret_enc')) .to eq(nil)
      end

      it 'returns value if it has been retained' do
        subject.set_retained('the_secret_enc', 'foo')
        expect( subject.get_retained('the_secret_enc') ).to eq('foo')
      end

      it 'returns the newest value if set twice' do
        subject.set_retained('the_secret_enc', 'foo')
        subject.set_retained('the_secret_enc', 'bar')
        expect( subject.get_retained('the_secret_enc') ).to eq('bar')
      end
    end

    context '#clear_retained' do
      it 'clears retained values' do
        subject.set_retained('the_secret_enc', 'foo')
        expect( subject.get_retained('the_secret_enc') ).to eq('foo')

        subject.clear_retained('the_secret_enc')
        expect( subject.get_retained('the_secret_enc') ).to eq(nil)
      end
    end
  end

  context 'model tests' do
    subject { model.new }
    let(:model) { NormalModelNoRetain }
    
    context '#the_secret=' do
      it 'changes the database' do
        expect { subject.the_secret = 'foo' }.to change { subject['the_secret_enc'] }.from(nil)
      end

      it 'calls KMS' do
        expect_any_instance_of(KmsRails::Aws::KMS::Client).to receive(:generate_data_key)
          .once
          .with(hash_including(key_id: 'alias/a', key_spec: 'AES_256'))
          .and_call_original

        subject.the_secret = 'foo'
      end

      it 'sets the field to nil if called with nil' do
        subject.the_secret = 'foo'
        expect { subject.the_secret = nil }.to change { subject['the_secret_enc'] }.to(nil)
      end
    end

    context '#the_secret' do
      it 'decrypts the value and calls kms' do
        subject.the_secret = 'foo'

        expect_any_instance_of(KmsRails::Aws::KMS::Client).to receive(:decrypt)
          .once
          .and_call_original

        expect(subject.the_secret).to eq('foo')
      end
    end

    context '#the_secret_enc' do
      let(:decoded) { {'key' => 'YmF6', 'iv' => 'Zm9v', 'blob' => 'YmFy'} } # Base64 encoded values
      let(:encoded) { "\x83\xA3key\xA3baz\xA2iv\xA3foo\xA4blob\xA3bar".b }

      it 'decodes the messagepack format' do
        subject['the_secret_enc'] = encoded
        expect(subject.the_secret_enc).to eq(decoded)
      end

      it 'returns nil if field is nil' do
        subject['the_secret_enc'] = nil
        expect(subject.the_secret_enc).to eq(nil)
      end
    end

    context 'retain' do
      context '#the_secret / #the_secret_clear' do
        before(:each) do
          subject.the_secret = 'bar'
        end

        context 'retain off' do
          it 'decrypts every time when retain is disabled' do
            expect_any_instance_of(KmsRails::Aws::KMS::Client).to receive(:decrypt)
              .twice
              .and_call_original

            expect(subject.the_secret).to eq('bar')
            expect(subject.the_secret).to eq('bar')
          end
        end

        context 'retain on' do
          let(:model) { NormalModelRetain }

          it 'doesn\'t decrypt when it has already been set' do
            expect_any_instance_of(KmsRails::Aws::KMS::Client).not_to receive(:decrypt)

            expect(subject.the_secret).to eq('bar')
            expect(subject.the_secret).to eq('bar')
          end

          it 'decrypts only once when cleared' do
            subject.the_secret_clear

            expect_any_instance_of(KmsRails::Aws::KMS::Client).to receive(:decrypt)
              .once
              .and_call_original

            expect(subject.the_secret).to eq('bar')
            expect(subject.the_secret).to eq('bar')
          end
        end
      end
    end
  end

  context 'msgpack' do
    subject { model.new }
    let(:secret) { {'a' => 'b', 'q' => 6, 'h' => [1,2,3,4]} }

    context 'enabled' do
      let(:model) { NormalModelMsgPack }

      it 'serializes and deserializes values correctly' do
        subject.the_secret = secret
        expect(subject.the_secret) .to eq(secret)
      end
    end

    context 'disabled' do
      let(:model) { NormalModelNoRetain }

      it 'serializes and deserializes values correctly' do
        subject.the_secret = secret
        expect(subject.the_secret) .to eq(secret.to_s)
      end
    end
  end

end