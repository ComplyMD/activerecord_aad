import sys
import json
from azure.identity import ManagedIdentityCredential

client_id = None
scope = 'https://management.azure.com/.default'

# If there is one arg, client_id is None. If there are two args, client_id is the second arg. If there are three args, scope is the third.
if len(sys.argv) == 2:
    client_id = sys.argv[1]
elif len(sys.argv) == 3:
    client_id = sys.argv[1]
    scope = sys.argv[2]
else:
    raise Exception("Invalid number of arguments")

credential = ManagedIdentityCredential(client_id=client_id)
response = credential.get_token_info(scope)

token_info = {
    'token': response.token,
    'expires_on': response.expires_on,
    'refresh_on': response.refresh_on
}

print(json.dumps(token_info, indent=2))