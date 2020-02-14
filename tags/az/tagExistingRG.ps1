#credit : https://blog.nicholasrogoff.com/2018/11/01/resource-tag-management-in-microsoft-azure/ - changes by me.
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

Connect-to-ARM

$resourceGroupName = "{reosurce group name}"
$location = "{location}"
  
#Tags
$product = "{product}"
$owner = "{email address}"
$build = "{Built by  01/03/2018 21:04:56}"
$expires = "{expiry date or 'never'}"
$environment = "{environment}"
#-- Add more tags here --
  
$rg = Get-azResourceGroup -name $resourceGroupName
$resourceTags = @{"product"=$product;"owner"=$owner;"build"=$build;"expires"=$expires;"environment"=$environment}

$rgTags = (Get-AzResourceGroup -Name $resourceGroupName).tags
if ($rgTags)
{
    $tagAction = Write-host "Existing tags found - Append or Replace"
    while("Append","Replace","A","R" -notcontains $tagAction)
    {
	    $tagAction = Read-Host "Existing tags found - Append or Replace"
    }
    switch -Wildcard ($tagAction)
    {
        "A*"
        {
            $resourceTags += $rgTags
        }
        "R*"
        {
            $resourceTags = $resourceTags
        }
    } 
}

$resourceTags
Set-azResource -Tag $resourceTags -ResourceId $rg.ResourceId -Force