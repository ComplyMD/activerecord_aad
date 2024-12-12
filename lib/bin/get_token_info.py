import sys
import json
from azure.identity import ManagedIdentityCredential

client_id = sys.argv[1] if len(sys.argv) == 2 else None
credential = ManagedIdentityCredential(client_id=client_id)
response = credential.get_token_info('https://management.azure.com/.default')

token_info = {
    'token': response.token,
    'expires_on': response.expires_on,
    'refresh_on': response.refresh_on
}
token_info_json = json.dumps(token_info)
print(token_info_json)