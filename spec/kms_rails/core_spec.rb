describe KmsRails::Core do
  let(:key_id) { nil }
  let(:context_key) { nil }
  let(:context_value) { nil }
  subject { KmsRails::Core.new(key_id: key_id, context_key: context_key, context_value: context_value) }

  before(:each) do
    KmsRails.configure do |config|
      config.alias_prefix = 'the-prefix/'
    end
  end

  context 'key_id' do
    context 'UUID key' do
      let(:key_id) { '1234abcd-12ab-34cd-56ef-1234567890ab' }
      it 'uses a UUID key as is' do
        expect(subject.key_id).to eq(key_id)
      end
    end

    context 'key with alias/' do
      let(:key_id) { 'alias/a-key' }
      it 'uses a key with alias/ prefix as is' do
        expect(subject.key_id).to eq(key_id)
      end
    end

    context 'key without alias/' do
      let(:key_id) { 'a-key' }
      it 'adds the prefix and alias/' do
        expect(subject.key_id).to eq('alias/the-prefix/a-key')
      end
    end

    context 'proc' do
      let(:key_id) { Proc.new { 'alias/the-proc-value' } }
      it 'resolves the proc' do
        expect(subject.key_id).to eq('alias/the-proc-value')
      end
    end
  end
end
