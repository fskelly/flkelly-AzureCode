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

$resourceGroupName = "{resource groups name}"
$location = "{location}"
#Tags
$product = "{product}"
$owner = "{email address}"
$build = "{Built by <CD tool or user> 01/03/2018 21:04:56}"
$expires = "{expiry date or 'never'}"
$environment = "{environment}"
#-- Add more tags here --

$rg = New-azResourceGroup -Location $location -Name $resourceGroupName
$resourceTags = @{"product"=$product;"owner"=$owner;"build"=$build;"expires"=$expires;"environment"=$environment}
Set-azResource -Tag $resourceTags -ResourceId $rg.ResourceId -Force