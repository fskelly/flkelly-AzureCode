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

#where to setup resources like 'South Africa North'
$location = ''
#name for the resource group 'testvpn01'                                   
$resourceGroup = ''
#name for vnet in azure 'vnet1'                                    
$vnet = ''
#name for your gateway public ip 'gwpubip-flkelly'                                           
$vnetGWIP = '' 
#public ip of your on-prem Gateway Device                                        
$gatewayip = ''
#preshared key for the connection                                     
$presharedKey = ''
#address range for Azure network for example '172.16.0.0/16'                                     
$addressRange = ''
#gateway subet, for example '172.16.255.0/27'                                     
$gatewaySubnet =''
#ip range for the frontend subnet '172.16.0.0/24'                                   
$frontEndSubnet = '' 
#your on-premises ip range                                   
$onPremRange = ''
 #a name for your gateway network 'azure-to-on-prem'                                    
$localNetworkGatewayName = ''                     
# a name for First subnet
$frontEnd = '' 

New-AzResourceGroup -Name $resourceGroup -Location $location
$subnet1 = New-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix $gatewaySubnet
$subnet2 = New-AzVirtualNetworkSubnetConfig -Name $frontEnd -AddressPrefix $frontEndSubnet
New-AzVirtualNetwork -Name $vnet -ResourceGroupName $resourceGroup -Location $location -AddressPrefix $addressRange -Subnet $subnet1, $subnet2

New-AzLocalNetworkGateway -Name $localNetworkGatewayName -ResourceGroupName $resourceGroup -Location $location -GatewayIpAddress $gatewayip -AddressPrefix $onPremRange
$gwpip= New-AzPublicIpAddress -Name $vnetGWIP -ResourceGroupName $resourceGroup -Location $location -AllocationMethod Dynamic
$vnet = Get-AzVirtualNetwork -Name $vnet -ResourceGroupName $resourceGroup
$subnet = Get-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnet
$gwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name gwipconfig1 -SubnetId $subnet.Id -PublicIpAddressId $gwpip.Id

#building vnetgateway name
$vnetGW = $vnet.Name + "-to-" + $onPremRange.Substring(0,$onPremRange.Length-3)
New-AzVirtualNetworkGateway -Name $vnetGW -ResourceGroupName $resourceGroup -Location $location -IpConfigurations $gwipconfig -GatewayType Vpn -VpnType RouteBased -GatewaySku VpnGw1
$gateway1 = Get-AzVirtualNetworkGateway -Name $vnetGW -ResourceGroupName $resourceGroup
$local = Get-AzLocalNetworkGateway -Name $localNetworkGatewayName -ResourceGroupName $resourceGroup
$connectionName = $onPremRange.Substring(0,$onPremRange.Length-3) + "-to-" + $vnet.Name
New-AzVirtualNetworkGatewayConnection -Name $connectionName -ResourceGroupName $resourceGroup -Location $location -VirtualNetworkGateway1 $gateway1 -LocalNetworkGateway2 $local -ConnectionType IPsec -RoutingWeight 10 -SharedKey $presharedKey