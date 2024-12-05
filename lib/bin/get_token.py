import sys
from azure.identity import ManagedIdentityCredential

credential = ManagedIdentityCredential()

# Get an access token
token = credential.get_token('https://management.azure.com/.default')
print(token.token)

# # Check if the correct number of arguments are provided
# if len(sys.argv) == 2:
#     # Get the client_id from the command-line arguments
#     client_id = sys.argv

#     # Create a ManagedIdentityCredential instance
#     credential = ManagedIdentityCredential(client_id=client_id)

#     # Get an access token
#     token = credential.get_token('https://management.azure.com/.default')
#     print(token.token)
# else:
#     credential = ManagedIdentityCredential()

#     # Get an access token
#     token = credential.get_token('https://management.azure.com/.default')
#     print(token.token)