def swap_connection
  original_connection = ActiveRecord::Base.remove_connection
  yield original_connection.configuration_hash
ensure
  ActiveRecord::Base.establish_connection(original_connection)
end

def run_with_connection(overrides={azure_managed_identity: {client_id: '1234-2345-3456'}})
  swap_connection do |orig_connection|
    ActiveRecord::Base.establish_connection(orig_connection.deep_merge(overrides))
    yield ActiveRecord::Base.connection_pool if block_given?
  end
end

def dummy_token(header: {}, payload: {}, signature: 'signature')
  default_header = { alg: 'HS256', typ: 'JWT' }
  default_payload = { some_opaque_value: Time.now }

  header = default_header.merge(header)
  payload = default_payload.merge(payload)

  "#{Base64.urlsafe_encode64(header.to_json)}.#{Base64.urlsafe_encode64(payload.to_json)}.#{Base64.urlsafe_encode64(signature)}"
end

def dummy_token_response(expires_in: nil, expires_on: nil, not_before: nil, token: {})
  token = token.merge({ header: {}, payload: {}, signature: 'signature' })
  expires_in = (expires_in || 60.minutes).to_i
  expires_on = (expires_on || (Time.now + expires_in)).to_i
  not_before = (not_before || (Time.now + expires_in)).to_i

  access_token = dummy_token(**token)
  {
    access_token: access_token,
    expires_in: expires_in,
    expires_on: expires_on,
    not_before: not_before
  }
end