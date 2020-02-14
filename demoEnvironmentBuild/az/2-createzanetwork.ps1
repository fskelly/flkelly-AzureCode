Write-Output "Creating networking components"
Write-Output "creating Hub and VPN Connection(s)"
#where to setup resources like 'South Africa North'
$vpnLocation = $(jq -r '.VPN.vpnLocation' settings.json)
#name for the resource group 'testvpn01'                                   
$vpnResourceGroup = $(jq -r '.VPN.vpnResourceGroup' settings.json)
#name for vnet in azure 'vnet1'                                    
$hubVNetName = $(jq -r '.VPN.hubVnetName' settings.json)
#name for your gateway public ip 'gwpubip-flkelly'                                           
$vnetGWIP = $(jq -r '.VPN.vnetGWIP' settings.json) 
#public ip of your on-prem Gateway Device                                        
$gatewayip = $(jq -r '.VPN.gatewayIP' settings.json) 
#preshared key for the connection                                     
$presharedKey = $(jq -r '.VPN.presharedKey' settings.json) 
#address range for Azure network for example '172.16.0.0/16'                                     
$addressRange = $(jq -r '.ZAHUB.addressRange' settings.json) 
#gateway subet, for example '172.16.255.0/27'                                     
$gatewaySubnet =$(jq -r '.ZAHUB.gatewaySubnet' settings.json) 
#ip range for the frontend subnet '172.16.0.0/24'                                   
$frontEndSubnet = $(jq -r '.ZAHUB.frontendRange' settings.json)  
#your on-premises ip range                                   
$onPremRange = $(jq -r '.ZAHUB.onPremRange' settings.json) 
 #a name for your gateway network 'azure-to-on-prem'                                    
$localNetworkGatewayName = $(jq -r '.VPN.gatewayName' settings.json)                      
# a name for First subnet
$frontEnd = $(jq -r '.ZAHUB.frontendName' settings.json) 

Write-Output "Creating required subnets for Hub"
$subnet1 = New-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix $gatewaySubnet
$subnet2 = New-AzVirtualNetworkSubnetConfig -Name $frontEnd -AddressPrefix $frontEndSubnet

Write-Output "[Done]"

Write-Output "Creating VNets with subnets associated to them"
New-AzVirtualNetwork -Name $hubVNetName -ResourceGroupName $vpnResourceGroup -Location $vpnLocation -AddressPrefix $addressRange -Subnet $subnet1, $subnet2

Write-Output "Creating Local Network Gateway"
New-AzLocalNetworkGateway -Name $localNetworkGatewayName -ResourceGroupName $vpnResourceGroup -Location $vpnLocation -GatewayIpAddress $gatewayip -AddressPrefix $onPremRange

Write-Output "Crating public ip"
$gwpip= New-AzPublicIpAddress -Name $vnetGWIP -ResourceGroupName $vpnResourceGroup -Location $vpnLocation -AllocationMethod Dynamic
$hubVNet = Get-AzVirtualNetwork -Name $hubVNetName -ResourceGroupName $vpnResourceGroup
$subnet = Get-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $hubVNet
$gwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name gwipconfig1 -SubnetId $subnet.Id -PublicIpAddressId $gwpip.Id

#building vnetgateway name
#feel free to comment out the below to skip the VPN components
Write-Output "Creating Virtual network gateway and connections"
Write-Output "This might take a while, grab some coffee :)"
$vnetGW = $hubVNetName + "-to-" + $onPremRange.Substring(0,$onPremRange.Length-3)
New-AzVirtualNetworkGateway -Name $vnetGW -ResourceGroupName $vpnResourceGroup -Location $vpnLocation -IpConfigurations $gwipconfig -GatewayType Vpn -VpnType RouteBased -GatewaySku Basic
$gateway1 = Get-AzVirtualNetworkGateway -Name $vnetGW -ResourceGroupName $vpnResourceGroup
$local = Get-AzLocalNetworkGateway -Name $localNetworkGatewayName -ResourceGroupName $vpnResourceGroup
$connectionName = $onPremRange.Substring(0,$onPremRange.Length-3) + "-to-" + $hubVNet.Name
New-AzVirtualNetworkGatewayConnection -Name $connectionName -ResourceGroupName $vpnResourceGroup -Location $vpnLocation -VirtualNetworkGateway1 $gateway1 -LocalNetworkGateway2 $local -ConnectionType IPsec -RoutingWeight 10 -SharedKey $presharedKey
