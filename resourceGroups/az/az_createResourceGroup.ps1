# Connect to Azure with a browser sign in token
Connect-AzAccount
  
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


$resourceGroup = Read-Host "Enter Resource Group Name to be created"
write-host "Listing all locations"
Get-AzLocation | Select-Object -Property location
$location = Read-Host "Enter location in which resource group shold be created" 
New-AzResourceGroup -Name $resourceGroup -Location $location
