# frozen_string_literal: true
require 'httparty'

module ActiveRecordAAD
  class IdentityManager
    attr_reader :properties, :access_token_expires_on, :access_token_fetched_at

    ENDPOINT    = 'http://169.254.169.254/metadata/identity/oauth2/token'
    API_VERSION = '2018-02-01'
    RESOURCE    = 'https://ossrdbms-aad.database.windows.net'

    # If props is a string, it is assumed to be the client_id and converted to a hash.
    def initialize(props)
      @properties = default_properties
      @properties[:client_id] = props if props.is_a?(String)
      @properties = @properties.merge(props.symbolize_keys) if props.is_a?(Hash)
    end

    # Constructs the URL for fetching the OAuth2 token.
    # The URL includes the endpoint, API version, resource, and client ID.
    def url
      encoded_resource = URI.encode_www_form_component(@properties[:resource])
      "#{@properties[:endpoint]}?api-version=#{@properties[:api_version]}&resource=#{encoded_resource}&client_id=#{@properties[:client_id]}"
    end

    # Returns cached token or fetches a new one
    def access_token
      if token_expiring?
        @access_token, access_token_expires_on = fetch_access_token

        # TODO: validate token
        # header, payload, signature = @access_token.split('.')
        # decoded_payload = JSON.parse(Base64.decode64(payload))
        # access_token_expires_on = decoded_payload['exp']

        @access_token_expires_on = Time.at(access_token_expires_on.to_i)
        @access_token_fetched_at = Time.now
      end

      @access_token
    end

    # Applies the access token to the database configuration.
    # This method duplicates the existing database configuration hash,
    # merges it with a new password (the access token), and freezes the new configuration.
    def apply(db_config)
      new_config = db_config.configuration_hash.dup.merge(password: access_token).freeze
      db_config.instance_variable_set('@configuration_hash', new_config)
    end

    private

    # Default properties for ActiveRecordAAD:
    # - endpoint: The URL endpoint to fetch the OAuth2 token from.
    # - api_version: The API version to use when fetching the token.
    # - resource: The resource for which the token is requested.
    # - timeout: The timeout for the request to fetch the token.
    # - fetch_token: Determines when to fetch the token.
    #   - 0: Fetch token on every request.
    #   - > 0: Fetch token every x seconds.
    #   - < 0: Fetch token x seconds before expiration.
    def default_properties
      {
        endpoint: ENDPOINT,
        api_version: API_VERSION,
        resource: RESOURCE,
        fetch_token: -300,
        timeout: 10
      }
    end

    # Determines the expiration time of the access token based on the fetch_token property.
    # - If fetch_token is 0, the token is fetched on every request, so the expiration time is the current time.
    # - If fetch_token is greater than 0, the token is fetched every x seconds, so the expiration time is the current time plus x seconds.
    # - If fetch_token is less than 0, the token is fetched x seconds before expiration, so the expiration time is the current expiration time minus x seconds.
    def token_expiring?
      return true if @access_token.blank?

      fetch_at = case @properties[:fetch_token]
      when 0
        Time.now
      when ->(n) { n > 0 }
        @access_token_fetched_at + @properties[:fetch_token]
      when ->(n) { n < 0 }
        @access_token_expires_on + @properties[:fetch_token]
      else
        raise InvalidArgumentError
      end

      Time.now >= fetch_at
    end

    # Fetches the access token from the specified URL.
    def fetch_access_token
      begin
        access_token_response = HTTParty.get(url, headers: { 'Metadata' => 'true' }, timeout: @properties[:timeout])
      rescue StandardError => e
        raise "ActiveRecordAAD: unable to get access token: `#{e.message}`"
      end

      unless access_token_response.success?
        raise "ActiveRecordAAD: unable to get access token: `#{access_token_response.code} - #{access_token_response.message}`"
      end

      access_token_response.values_at 'access_token', 'expires_on'
    end
  end
end