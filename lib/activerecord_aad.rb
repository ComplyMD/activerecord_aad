# frozen_string_literal: true
require 'rails'
require 'httparty'
require 'activerecord_aad/version'
require 'activerecord_aad/active_record/connection_adapters/connection_pool'

module ActiveRecordAAD
  module ActiveRecord
    class Railtie < ::Rails::Railtie
      railtie_name :activerecord_aad

      initializer 'activerecord_aad.config', before: :load_config_initializers do
        ::ActiveRecord::ConnectionAdapters::ConnectionPool.prepend ActiveRecordAAD::ActiveRecord::ConnectionAdapters::ConnectionPool
      end
    end
  end
end
