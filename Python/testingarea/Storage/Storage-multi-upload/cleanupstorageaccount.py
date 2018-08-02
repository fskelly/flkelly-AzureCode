import os, sys
import os, uuid, sys
from azure.storage.blob import BlockBlobService, PublicAccess

storage_account_key = '035w4Ag27N/Kkj+vgCrQrgJP6RFkO/MSwyFcdIVfeoSxnLwDQ3yscSuSyeyAmACRdDu+t4qxwJ6tsNKrAJ8Glg=='

## Azure Blob functions
block_blob_service = BlockBlobService(account_name='flkellystorage', account_key=storage_account_key)
# Create a container called 'quickstartblobs'.
container_name ='pythonmultiuploads'


# Clean up resources. This includes the container and the temp files
block_blob_service.delete_container(container_name)