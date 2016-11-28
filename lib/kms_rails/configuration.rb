module KmsRails
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :fake_kms_api

    def initialize
      @fake_kms_api = false
    end
  end
end