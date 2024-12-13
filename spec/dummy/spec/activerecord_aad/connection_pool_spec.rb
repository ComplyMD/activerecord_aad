require 'rails_helper'
require 'connection_helper'
require 'timecop'

RSpec.describe ActiveRecordAAD::ActiveRecord::ConnectionAdapters::ConnectionPool do

  let(:response_double) { double('response', success?: true, code: 200, message: 'OK', parsed_response: dummy_token_response(expires_in: 5.minutes))}

  before do
    allow(HTTParty).to receive(:get).and_return(response_double)
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

      it 'fetches a new token once' do
        run_with_connection do |connection_pool|
          allow(connection_pool.identity_manager).to receive(:fetch_token_http).and_return(dummy_token_response(expires_in: 10.minutes))
          expect(connection_pool.identity_manager).to receive(:refresh_token).once.and_call_original

          connection_pool.identity_manager.access_token
          Timecop.travel(5.minutes.from_now) do
            connection_pool.identity_manager.access_token
            connection_pool.identity_manager.access_token
          end
        end
      end

      it 'refreshes an expired token' do
        run_with_connection do |connection_pool|
          expect(connection_pool.identity_manager).to receive(:refresh_token).twice.and_call_original

          Timecop.travel(10.minutes.from_now) do
            connection_pool.identity_manager.access_token

            Timecop.travel(1.hour.from_now) do
              connection_pool.identity_manager.access_token
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