# frozen_string_literal: true
require 'rails'
require 'httparty'
require 'activerecord_aad/version'
require 'activerecord_aad/active_record/connection_adapters/connection_pool'

module ActiveRecordAAD
  module ActiveRecord
    class Railtie < ::Rails::Railtie
      railtie_name :activerecord_aad

      initializer 'activerecord_aad.config' do
        ActiveSupport.on_load(:active_record) do
          ::ActiveRecord::ConnectionAdapters::ConnectionPool.prepend ActiveRecordAAD::ActiveRecord::ConnectionAdapters::ConnectionPool
        end
      end
    end
  end

  def self.initialize!
    ::ActiveRecord::Base.connection_pool.checkout_new_connection
  end
end
