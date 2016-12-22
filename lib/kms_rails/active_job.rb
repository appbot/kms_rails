require 'msgpack'
require 'active_job'
require 'kms_rails/core'

module KmsRails
  module ActiveJob
    class << self
      def included base
        base.extend ClassMethods
      end
    end
    
    module ClassMethods
      def kms_arg(field_number, key_id:, msgpack: false, context_key: nil, context_value: nil)
        kms_args([field_number], key_id: key_id, msgpack: msgpack, context_key: context_key, context_value: context_value)
      end

      def kms_args(field_numbers, key_id:, msgpack: false, context_key: nil, context_value: nil)
        enc = Core.new(key_id: key_id, context_key: context_key, msgpack: msgpack, context_value: context_value)

        define_method 'serialize_arguments' do |args|
          args = args.dup

          field_numbers.each do |i|
            # We skip encoding if nil or if already encrypted
            unless args[i].nil? || (args[i].class == Hash && args[i].keys.to_set == ['key', 'iv', 'blob'].to_set)
              args[i] = enc.encrypt64(args[i])
            end
          end

          super(args)
        end

        define_method 'deserialize_arguments' do |args|
          args = super(args).dup

          field_numbers.each do |i|
            args[i] = enc.decrypt64(args[i]) unless args[i].nil?
          end

          args
        end
      end
    end
  end
end

if Object.const_defined?('ActiveJob')
  ActiveJob::Base.send(:include, KmsRails::ActiveJob)
end
