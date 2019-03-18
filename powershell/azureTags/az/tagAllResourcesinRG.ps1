#credit : https://blog.nicholasrogoff.com/2018/11/01/resource-tag-management-in-microsoft-azure/

Function Connect-to-ARM
{
    Login-AzAccount
  
    $subscriptions = Get-AzSubscription | Sort-Object SubscriptionName | Select-Object Name,SubscriptionId
    [int]$subscriptionCount = $subscriptions.count
    Write-Host "Found" $subscriptionCount "Subscriptions"
    $i = 0
    foreach ($subscription in $subscriptions)
    {
      $subValue = $i
      Write-Host $subValue ":" $subscription.Name "("$subscription.SubscriptionId")"
      $i++
    }
    Do 
    {
      [int]$subscriptionChoice = read-host -prompt "Select number & press enter"
    } 
    until ($subscriptionChoice -le $subscriptionCount)
    
    Write-Host "You selected" $subscriptions[$subscriptionChoice].Name
    Select-AzSubscription -SubscriptionId $subscriptions[$subscriptionChoice].SubscriptionId
}
#Login (ARM)
Connect-to-ARM

#================================================================
# Apply Tags to all Resources in a Resource Group
#
# Last updated: 2017-06-20 by Nicholas Rogoff
#================================================================
    
#Set Variables
#$subscriptionName = "{subscription name}"

#Tags
$product = "{product}"
$owner = "{email address}"
$build = "{Built by  01/03/2018 21:04:56}"
$expires = "{expiry date or 'never'}"
$environment = "{environment}"

#-- Add more tags here --
  


#$resourceGroupName = "{resource groups name}"
$resourceGroupName = "{resource group name}"
  
$resources = Get-azResource | Where-Object {$_.ResourceGroupName -eq $resourceGroupName}
  
foreach ($resource in $resources)
{
    # Ignore certain types of resources
    if($resource.ResourceType -ne "Microsoft.Web/sites/slots")
    {
        $resourceTags = $resource.Tags
        #== start debug
        Write-Verbose -Message "--- Tags found for $($resource.Name)--- " -Verbose
        $resource.Tags
        #== end debug
  
        #== Check if one of the tags ('owner') exists and assume the rest are there! This check can be made more comples if need be
        if($resourceTags -and $resourceTags.count -gt 0 -and $resourceTags.values.Contains('owner'))
        {
            Write-Verbose -Message "Resource $($resource.Name) has 'segment-name' tag, so will NOT apply additional tags" -Verbose
        }
        else
        {
            Write-Verbose -Message "Resource $($resource.Name) does NOT any tags" -Verbose
            #-- add tags in the next line
            $resourceTags += @{"product"=$productName;"owner"=$owner;"build"=$build;"expires"=$expires;"environment"=$environment}
            Set-azResource -Tag $resourceTags -ResourceId $resource.ResourceId
            Write-Verbose -Message "Resource $($resource.Name) has had tags applied" -Verbose
        }
    }
}