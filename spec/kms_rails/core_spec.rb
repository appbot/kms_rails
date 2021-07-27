describe KmsRails::Core do
  let(:key_id) { nil }
  let(:context_key) { nil }
  let(:context_value) { nil }
  subject { KmsRails::Core.new(key_id: key_id, context_key: context_key, context_value: context_value) }

  before(:each) do
    KmsRails.configure do |config|
      config.alias_prefix = 'the-prefix/'
      config.arn_prefix = 'arn:aws:foo:bar:'
    end
  end

  context 'key_id' do
    context 'UUID key' do
      let(:key_id) { '1234abcd-12ab-34cd-56ef-1234567890ab' }
      it 'adds arn prefix but nothing else' do
        expect(subject.key_id).to eq('arn:aws:foo:bar:1234abcd-12ab-34cd-56ef-1234567890ab')
      end
    end

    context 'key with alias/' do
      let(:key_id) { 'alias/a-key' }
      it 'adds arn prefix but nothing else' do
        expect(subject.key_id).to eq('arn:aws:foo:bar:alias/a-key')
      end
    end

    context 'key without alias/' do
      let(:key_id) { 'a-key' }
      it 'adds the alias and arn prefix and alias/' do
        expect(subject.key_id).to eq('arn:aws:foo:bar:alias/the-prefix/a-key')
      end
    end

    context 'proc' do
      let(:key_id) { Proc.new { 'alias/the-proc-value' } }
      it 'resolves the proc' do
        expect(subject.key_id).to eq('alias/the-proc-value')
      end
    end

    context 'symbol' do
      let(:key_id) { :test }
      it 'raises exception' do
        expect { subject.key_id }.to raise_error(RuntimeError)
      end
    end
  end
end
