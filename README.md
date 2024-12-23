# activerecord-aad

This gem enables using an Azure Active Directory Managed Identity to connect to an Azure Database Service.

## Installation

To install the gem, follow these steps:

1. Add `gem 'activerecord_aad'` to your Gemfile.
2. Run `bin/bundle install` to install the gem.

## Setup

To set up the gem, follow one of the guides below based on your database:

- MySQL: https://learn.microsoft.com/en-us/azure/mysql/single-server/how-to-connect-with-managed-identity
- PostgreSQL: https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-connect-with-managed-identity

Add the `client_id` from the Azure AD Managed Identity to your `config/database.yml` file with the key `azure_managed_identity`.

Example configuration:
```yaml
production:
  adapter: mysql2
  reconnect: true
  host: my-app.mysql.database.azure.com
  #provide client id and specify other properties
  azure_managed_identity:
    client_id: 00000000-0000-0000-000000000000
  database: app
  username: MyAppsManagedIdentity@my-app
  sslca: /opt/ssl/BaltimoreCyberTrustRoot.crt.pem
  sslverify: true
  sslcipher: 'AES256-SHA'
```

## How it works

The password field in the database configuration is replaced with an access token from Azure which is passed to the adapter to establish the connection. Whenever the token needs to be replaced, a call is made to the Azure endpoint and the token is updated.

### Dependencies
If using the python option to fetch tokens, then python, pip and the azure.identity module need to be installed. HTTP requests will work in VMs, python is better for containers.


### Default Properties

The default properties for `ActiveRecordAAD` include:
- `endpoint`: The URL endpoint to fetch the OAuth2 token from.
- `api_version`: The API version to use when fetching the token.
- `resource`: The resource for which the token is requested.
- `timeout`: The timeout for the request to fetch the token.
- `enable_cleartext_plugin`: Whether to enable the cleartext plugin for MySQL databases.
- `client_id`: The client ID for the Azure Managed Identity.
- `http`: Whether to use HTTP to fetch the token.
- `python`: Whether to use Python to fetch the token.
