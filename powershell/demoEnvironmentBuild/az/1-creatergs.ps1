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

Write-Output "Creating Azure Resource Groups"
# Create as many resource groups as you needs. This is my naming convention.
$rgsToCreate = "flkelly-zan-net-test","flkelly-zan-vms-test","flkelly-weu-net-test","flkelly-weu-vms-test","flkelly-weu-monitor-test","flkelly-neu-net-test","flkelly-neu-vms-test"
foreach ($rg in $rgsToCreate)
{
  $region = $rg.Substring(8,3)
  Write-Output "Creating $rg Resource Group"
  switch ($region) 
  {
    "zan" { $rgLocation = "SouthAfricaNorth" }
    "weu" { $rgLocation = "WestEurope" }
    "neu" { $rgLocation = "NorthEurope" }
    Default { $rgLocation = "SouthAfricaNorth" }

  }
  New-AzResourceGroup -Name $rg -Location $rgLocation
}