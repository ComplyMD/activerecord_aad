def swap_connection
  original_connection = ActiveRecord::Base.remove_connection
  yield original_connection.configuration_hash
ensure
  ActiveRecord::Base.establish_connection(original_connection)
end

def run_with_connection(overrides={azure_managed_identity: {client_id: '1234-2345-3456', fetch_token: -300}})
  swap_connection do |orig_connection|
    ActiveRecord::Base.establish_connection(orig_connection.deep_merge(overrides))
    yield ActiveRecord::Base.connection_pool if block_given?
  end
end

def dummy_token(header: {}, payload: {}, signature: 'signature')
  header = { alg: 'HS256', typ: 'JWT' }.merge(header)
  payload = { exp: Time.now.to_i + 60.minutes}.merge(payload)
  dummy_token = "#{Base64.urlsafe_encode64(header.to_json)}.#{Base64.urlsafe_encode64(payload.to_json)}.#{Base64.urlsafe_encode64(signature)}"
end