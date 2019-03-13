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

$ResourceGroup = "RG_Name"

#Get all tags from Resource (VM)
$tags = (Get-AzResourceGroup -ResourceGroupName $ResourceGroup).tags

$vms = Get-AzVM -ResourceGroupName $ResourceGroup
foreach ($vm in $vms)
{
    $UpdateTag = Set-AzResource -Tag $tags -ResourceName $vm.name -ResourceGroupName $ResourceGroup -ResourceType Microsoft.Compute/virtualMachines
}