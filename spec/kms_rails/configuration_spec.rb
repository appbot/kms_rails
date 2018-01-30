describe KmsRails::ConfigurationBase do
  subject { Class.new.extend KmsRails::ConfigurationBase }

  context 'without configuration' do
    it 'provides defaults' do
      expect(subject.configuration.fake_kms_api).to eq(false)
      expect(subject.configuration.alias_prefix).to eq('')
    end
  end

  context 'with configuration' do
    before do
      subject.configure do |c|
        c.fake_kms_api = 'barfoo'
        c.alias_prefix = 'foobar'
      end
    end

    it 'provides as configured' do
      expect(subject.configuration.fake_kms_api).to eq('barfoo')
      expect(subject.configuration.alias_prefix).to eq('foobar')
    end

    it 'provides defaults when reset' do
      subject.reset_config
      expect(subject.configuration.fake_kms_api).to eq(false)
      expect(subject.configuration.alias_prefix).to eq('')
    end
  end

  it 'has configuration extended into base' do
    expect(KmsRails.is_a? KmsRails::ConfigurationBase ).to be(true)
  end

  it 'has configuration accessible from base' do
    expect(KmsRails.configuration.is_a? KmsRails::ConfigurationBase::Configuration).to be(true)
  end
end
