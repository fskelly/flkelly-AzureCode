function select-AzureSubscription
{
  Connect-AzureRmAccount
  $subscriptions = Get-AzureRMSubscription | Sort-Object SubscriptionName | Select-Object Name,SubscriptionId
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
  Set-AzureRmContext -SubscriptionId $subscriptions[$subscriptionChoice].SubscriptionId

}

select-AzureSubscription

$RGname=Read-host " Enter the name of the RG to Use"
if (Get-AzureRmResourceGroup -Name $RGname -ErrorAction SilentlyContinue ) 
{
}
else
{
  write-host "$RGname does not exist, Creating it for you"
  New-AzureRmResourceGroup -Name $RGname -Location westeurope
}

$nsgname=Read-Host "Enter the name of the NSG to use"

if (Get-AzureRmNetworkSecurityGroup -Name $nsgname -ErrorAction SilentlyContinue ) 
{
}
else
{
  write-host "$nsgname does not exist, Creating it for you"
  New-AzureRmNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname -Location westeurope
}


$ports=8081,8080,1234
$priority = 3891

$direction = Read-Host "Inbound or Outbound"

while("In","Out","P","I","O" -notcontains $direction)
{
	$direction = Read-Host "Inbound or Outbound"
} 
switch -Wildcard ($direction)
{
    "I*"{
            $direction = "inbound"
        }
    "O*"{
            $direction = "outbound"
        }
} 

foreach ($port in $ports)
{
  $rulename="allowPort$port$direction"
  

  # Get the NSG resource
  $resource = Get-AzureRmResource | Where-Object {$_.ResourceGroupName -eq $RGname -and $_.ResourceType -eq "Microsoft.Network/networkSecurityGroups"} 
  $nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgname -ResourceGroupName $RGname 

  # Add the inbound security rule.
  Write-Host "Adding inbound rule for port $port - $direction"
  $nsg | Add-AzureRmNetworkSecurityRuleConfig -Name $rulename -Description "Allow port $port - $direction" -Access Allow `
    -Protocol * -Direction $direction -Priority $priority -SourceAddressPrefix "*" -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange $port

  # Update the NSG.
  $nsg | Set-AzureRmNetworkSecurityGroup
  $priority++
  
}

