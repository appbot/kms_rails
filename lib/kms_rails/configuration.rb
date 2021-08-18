module KmsRails
  module ConfigurationBase
    attr_writer :configuration

    class Configuration
      attr_accessor :kms_client, :alias_prefix, :arn_prefix

      def initialize
        @kms_client   = nil
        @alias_prefix = ''
        @arn_prefix   = ''
      end
    end

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(self.configuration)
    end

    def reset_config
      @configuration = Configuration.new
    end
  end

  extend ConfigurationBase
end
