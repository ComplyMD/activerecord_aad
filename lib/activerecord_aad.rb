# frozen_string_literal: true

module Azure
  module ActiveDirectory
    module ActiveRecord

      module HashConfig

        def configuration_hash
          hash = super.dup.with_indifferent_access
          if hash[:azure_managed_identity].present?
            @managed_identity_manager ||= ManagedIdentityManager.new(hash)
            @managed_identity_manager.apply
          end
          hash.symbolize_keys!.freeze
          hash
        end

      end

      class ManagedIdentityManager
        URL = 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fossrdbms-aad.database.windows.net'

        attr_reader :config, :url

        def initialize(conf)
          raise "ActiveRecordAAD: invalid config: `#{conf}`" unless conf.is_a?(Hash)
          @config = conf
          @client_id = config[:azure_managed_identity]
          @url = URL
          @url += "&client_id=#{@client_id}" if @client_id.present?
        end

        def apply
          config[:password] = access_token
          config[:enable_cleartext_plugin] = true if config[:adapter] == 'mysql2'
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
