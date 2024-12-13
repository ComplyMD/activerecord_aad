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
      @properties = default_properties.merge(props.symbolize_keys)
      @logger = Rails.logger.tagged('ActiveRecordAAD')
    end

    def logger(*tags)
      @logger.tagged(*tags)
    end

    # Constructs the URL for fetching the OAuth2 token.
    # The URL includes the endpoint, API version, resource, and client ID.
    def url
      encoded_resource = URI.encode_www_form_component(@properties[:resource])
      "#{@properties[:endpoint]}?api-version=#{@properties[:api_version]}&resource=#{encoded_resource}&client_id=#{@properties[:client_id]}"
    end

    # Returns cached token or fetches a new one
    def access_token
      logger('access_token').info('Start')

      if token_expiring?
        logger('access_token').info('Token expired')
        refresh_token
      end

      @access_token
    end

    # Applies the access token to the database configuration.
    # This method duplicates the existing database configuration hash,
    # merges it with a new password (the access token), and freezes the new configuration.
    def apply(db_config)
      logger('apply').info('Applying token')
      new_config = db_config.configuration_hash.dup.merge(password: access_token, enable_cleartext_plugin: @properties[:enable_cleartext_plugin]).freeze
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
        timeout: 5,
        enable_cleartext_plugin: true,
        client_id: nil,
        http: true,
        python: true
      }
    end

    # Determines the expiration time of the access token.
    def token_expiring?
      return true if @fetched_at.nil?

      (@expires_on <= Time.now) || (@refresh_on <= Time.now)
    end

    def fetch_token_http
      response = HTTParty.get(@properties[:endpoint], query: {
        api_version: @properties[:api_version],
        resource: @properties[:resource],
        client_id: @properties[:client_id]
      }, headers: {
        'Metadata' => 'true'
      }, timeout: @properties[:timeout])

      if response.success?
        response = response.parsed_response
      else
        logger('fetch_token_http').info("Failed to fetch token or invalid token: : #{response.code} - #{response.message} - #{response.body}")
        nil
      end
    end

    def fetch_token_python
      response = nil

      begin
        response = JSON.parse `python3 #{File.expand_path('../bin/get_token_info.py', __dir__)} #{@properties[:client_id]}`.strip
      rescue StandardError => e
        logger('fetch_token_python').info("Failed to fetch token or invalid token")
      end

      response
    end


    # Fetches the access token from the specified URL.
    def refresh_token
      logger('refresh_token').info('Start')

      response = nil

      if @properties[:http]
        begin
          response = fetch_token_http
        rescue StandardError => http_error
          logger('refresh_token').info("HTTP: error getting access token: `#{http_error.message}`")
        end
      end

      if response.nil? && @properties[:python]
        begin
          response = fetch_token_python
        rescue StandardError => python_error
          logger('refresh_token').info("Python: error getting access token: `#{python_error.message}`")
        end
      end

      if response.nil?
        logger('refresh_token').info("Invalid Token: token nil")
        raise 'Invalid Response: token nil'
      end

      begin
        @access_token, expires_on, refresh_on = response.values_at('token', 'expires_on', 'refresh_on')
        @expires_on = Time.at(expires_on)
        @refresh_on = Time.at(refresh_on)
        @fetched_at = Time.now
      rescue StandardError => e
        logger('refresh_token').info("Invalid Token: #{e.message}")
        return false
      end

      logger('refresh_token').info("Fetched token: `#{@access_token[0..5]}...REDACTED...#{@access_token[-5..-1]}`. Expires on: #{@expires_on}")

      true
    end
  end
end
