# activerecord-aad

This gem enables using an Azure ActiveDirectory Managed Identity to connect to an Azure Database Service

## Installation

- Add `gem :activerecord_aad` to your Gemfile.
- Run `bin/bundle install`

## Setup

Follow one of the following guides:
- MySQL: https://learn.microsoft.com/en-us/azure/mysql/single-server/how-to-connect-with-managed-identity
- PostgreSQL: https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-connect-with-managed-identity

Add the `client_id` from the Azure AD Managed Identity and add it to your `config/database.yml` file with the key `azure_managed_identity`

Example:
```yaml
production:
  adapter: mysql2
  reconnect: true
  host: my-app.mysql.database.azure.com
  azure_managed_identity: 91cb2200-004b-4577-a8ca-a5fa9c082485
  database: app
  username: MyAppsManagedIdentity@my-app
  sslca: /opt/ssl/BaltimoreCyberTrustRoot.crt.pem
  sslverify: true
  sslcipher: 'AES256-SHA'
```

## How it works

Whenever a new database connection is needed, a call is made to "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fossrdbms-aad.database.windows.net&client_id=#{database_yml_azure_managed_identity}" to get a new access key. That access key is added as the password to the database configuration that is passed to the adapter to establish the connection.