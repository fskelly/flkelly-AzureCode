#credit : https://blog.nicholasrogoff.com/2018/11/01/resource-tag-management-in-microsoft-azure/


$resourceGroupName = "{resource groups name}"
$location = "{location}"
  
#Tags
$product = "{product}"
$owner = "{email address}"
$build = "{Built by  01/03/2018 21:04:56}"
$expires = "{expiry date or 'never'}"
$environment = "{environment}"
#-- Add more tags here --
  
$rg = Get-AzureRmResourceGroup $resourceGroupName
$resourceTags = @{"product"=$product;"owner"=$owner;"build"=$build;"expires"=$expires;"environment"=$environment}
Set-AzureRmResource -Tag $resourceTags -ResourceId $rg.ResourceId -Force