require 'rails_helper'
require 'connection_helper'
require 'timecop'

RSpec.describe ActiveRecordAAD::ActiveRecord::ConnectionAdapters::ConnectionPool do
  let(:identity_manager_class) { ActiveRecordAAD::ActiveRecord::ManagedIdentityManager }

  before do
    Rails.cache.delete('activerecord_aad_access_token')
    first_response = [dummy_token, (Time.now + 5.minutes).to_i.to_s]
    second_response = [dummy_token, (Time.now + 15.minutes).to_i.to_s]

    response_double = double('response', success?: true, code: 200, message: 'OK')
    allow(HTTParty).to receive(:get).and_return(response_double, response_double, response_double)
    allow(response_double).to receive(:values_at).with('access_token', 'expires_on').and_return(first_response, second_response)
  end

  describe '#checkout_new_connection' do
    context 'when azure_managed_identity is present in db_config' do
      it 'sets and applies ManagedIdentityManager' do
        run_with_connection do |connection_pool|
          expect(connection_pool.identity_manager).not_to be_nil
          expect(connection_pool.identity_manager).to receive(:apply)

          connection_pool.checkout_new_connection
        end
      end

      context 'when fetch_token is 0' do
        it 'always fetches a new token' do
          run_with_connection(azure_managed_identity: {fetch_token: 0}) do |connection_pool|
            expect(connection_pool.identity_manager).to receive(:fetch_access_token).twice.and_call_original

            connection_pool.identity_manager.access_token
            connection_pool.identity_manager.access_token
          end
        end
      end

      context 'when fetch_token is > 0' do
        context 'when specified time has not elapsed' do
          it 'does not fetch a new token' do
            run_with_connection(azure_managed_identity: {fetch_token: 60}) do |connection_pool|
              expect(connection_pool.identity_manager).not_to receive(:fetch_access_token)

              connection_pool.identity_manager.instance_variable_set('@access_token_fetched_at', 50.seconds.ago)
              connection_pool.identity_manager.access_token
            end
          end
        end

        context 'when specified time has elapsed' do
          it 'fetches a new token' do
            run_with_connection(azure_managed_identity: {fetch_token: 60}) do |connection_pool|
              expect(connection_pool.identity_manager).to receive(:fetch_access_token).once.and_call_original

              Timecop.travel(Time.now + 5.minutes) do
                connection_pool.identity_manager.access_token
                connection_pool.identity_manager.access_token
              end
            end
          end
        end
      end

      context 'when fetch_token is < 0' do
        context 'when token is not expired' do
          it 'does not fetch a new token' do
            run_with_connection(azure_managed_identity: {fetch_token: -60}) do |connection_pool|
              expect(connection_pool.identity_manager).not_to receive(:fetch_access_token)

              connection_pool.identity_manager.access_token
            end
          end
        end

        context 'when token is expired' do
          it 'fetches a new token 3456' do
            run_with_connection(azure_managed_identity: {fetch_token: -60}) do |connection_pool|
              expect(connection_pool.identity_manager).to receive(:fetch_access_token).once.and_call_original

              Timecop.travel(Time.now + 5.minutes) do
                connection_pool.identity_manager.access_token
                connection_pool.identity_manager.access_token
              end
            end
          end
        end
      end
    end

    context 'when azure_managed_identity is not present in db_config' do
      it 'does not initialize ManagedIdentityManager' do
        run_with_connection({}) do |connection_pool|
          expect(connection_pool.identity_manager).to be_nil

          connection_pool.checkout_new_connection
        end
      end
    end
  end
end