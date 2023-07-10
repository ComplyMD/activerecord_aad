# frozen_string_literal: true

module Azure
  module ActiveDirectory
    module ActiveRecord

      module HashConfig

        def configuration_hash
          hash = super.dup
          if hash.key?(:azure_managed_identity)
            @managed_identity_manager ||= ManagedIdentityManager.new(hash[:azure_managed_identity])
            @managed_identity_manager.apply(hash)
          end
          hash.symbolize_keys!.freeze
          puts hash
          hash
        end

      end

      class ManagedIdentityManager
        URL = 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fossrdbms-aad.database.windows.net'

        attr_reader :config, :url

        def initialize(conf)
          raise "ActiveRecordAAD: invalid config: `#{conf}`" unless conf.is_a?(Hash)
          @config = conf.with_indifferent_access
          raise 'ActiveRecordAAD: missing client_id' unless config[:client_id].present?
          @client_id = config[:client_id]
          @url = URL
          @url += "&client_id=#{@client_id}" if @client_id.present?
        end

        def apply(hash)
          hash.merge!(password: access_token, enable_cleartext_plugin: true)
        end

        def access_token
          @access_token_response = HTTParty.get(url, { headers: { Metadata: 'true' } })
          raise "ActiveRecordAAD: unable to get access token: `#{@access_token_response}`" unless @access_token_response.ok?
          @access_token = @access_token_response['access_token']
        end

      end

      class Railtie < Rails::Railtie
        railtie_name :activerecord_aad

        initializer 'activerecord_aad.config' do
          ::ActiveRecord::DatabaseConfigurations::HashConfig.prepend HashConfig
        end

      end

    end
  end
end
