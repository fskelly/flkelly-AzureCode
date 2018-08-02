import os, sys
import os, uuid, sys
from azure.storage.blob import BlockBlobService, PublicAccess

storage_account_key = '035w4Ag27N/Kkj+vgCrQrgJP6RFkO/MSwyFcdIVfeoSxnLwDQ3yscSuSyeyAmACRdDu+t4qxwJ6tsNKrAJ8Glg=='

## Azure Blob functions
block_blob_service = BlockBlobService(account_name='flkellystorage', account_key=storage_account_key)
# Create a container called 'quickstartblobs'.
container_name ='pythonmultiuploads'
block_blob_service.create_container(container_name)

# Set the permission so the blobs are public.
block_blob_service.set_container_acl(container_name, public_access=PublicAccess.Container)

# open a directory
# Windows "\\" as \ is an escape character
path = "C:\\Users\\flkelly\\Pictures"
dirs = os.listdir( path )

# This would print all the files and directories
for file in dirs:
   print(file)
   full_path = os.path.join(path, file)
   print(full_path)
   print("\nUploading to Blob storage as blob" + file)
   # Upload the created file, use local_file_name for the blob name
   block_blob_service.create_blob_from_path(container_name, file, full_path)