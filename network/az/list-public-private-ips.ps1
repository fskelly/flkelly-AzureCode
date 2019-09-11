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
Set-AzContext -SubscriptionId $subscriptions[$subscriptionChoice].SubscriptionId

$AzureVMs = Get-AzVM  -status #-ResourceGroupName 'RGName'
foreach ($VM in $AzureVMs){
    $IPs = ($VM.NetworkProfile.NetworkInterfaces.id | Get-AzNetworkInterface).IpConfigurations
    foreach ($IP in $IPs ){
        if($IP.PublicIpAddress){
            $PublicIP = $Ip.PublicIpAddress | Get-AzResource | Get-AzPublicIpAddress
            $PublicIPName = $PublicIP.Name
            $PublicIPAllocation = $PublicIP.PublicIpAllocationMethod
            $PublicIPAddress = $PublicIP.IpAddress
        }
        else{
            $PublicIPName = ''
            $PublicIPAllocation = ''
            $PublicIPAddress = ''
        }

        [PSCustomObject]@{
            VM = $VM.Name
            VMState = $VM.PowerState
            ResourceGroup = $VM.ResourceGroupName
            IPConfigName = $IP.Name
            PrivateAddress = $IP.PrivateIpAddress
            PrivateAddressMethod = $IP.PrivateIpAllocationMethod
            PublicIPName = $PublicIPName
            PublicIPAllocation = $PublicIPAllocation
            PublicIPAddress = $PublicIPAddress
        }
    
    }
}
