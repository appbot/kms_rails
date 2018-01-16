module KmsRails
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(self.configuration)
  end

  def self.reset_config
    @configuration = Configuration.new
  end

  class Configuration
    attr_accessor :fake_kms_api, :alias_prefix

    def initialize
      @fake_kms_api = false
      @alias_prefix = ''
    end
  end
end
