# frozen_string_literal: true
require 'httparty'
require 'activerecord_aad/identity_manager'

module ActiveRecordAAD
  module ActiveRecord
    module ConnectionAdapters
      module ConnectionPool
        attr_reader :identity_manager

        # Checks out a new connection from the connection pool.
        # If the database configuration includes the :azure_managed_identity key,
        # it initializes a IdentityManager with the configuration and applies it to the db_config.
        # Then it calls the original checkout_new_connection method (super).
        def checkout_new_connection
          if db_config.configuration_hash[:azure_managed_identity]
            @identity_manager ||= ::ActiveRecordAAD::IdentityManager.new(db_config.configuration_hash[:azure_managed_identity])
            @identity_manager.apply db_config
          end

          super
        end
      end
    end
  end
end
