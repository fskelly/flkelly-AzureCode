$vpnResourceGroup = $(jq -r '.VPN.vpnResourceGroup' settings.json)
$spoke1 = $(jq -r '.ZASpoke1.Name' settings.json) 
$spoke1addressRange = $(jq -r '.ZASpoke1.addressSpace' settings.json) 
$spoke1Subnet = $(jq -r '.ZASpoke1.addressRange' settings.json)  
$spoke1location = $(jq -r '.ZASpoke1.location' settings.json)  
$spoke1resourceGroup = (jq -r '.ZASpoke1.resourceGroup' settings.json) 
Write-Output "Creating required subnets for ZAN Spoke"
$spsubnet1 = New-AzVirtualNetworkSubnetConfig -Name $spoke1 -AddressPrefix $spoke1Subnet
Write-Output "Creating VNets with subnets associated to them"
New-AzVirtualNetwork -Name $spoke1 -ResourceGroupName $spoke1resourceGroup -Location $spoke1location -AddressPrefix $spoke1addressRange -Subnet $spsubnet1

$hubVNetName = $(jq -r '.VPN.hubVnetName' settings.json)
$hubnetwork = Get-AzVirtualNetwork -Name $hubVNetName -ResourceGroupName $vpnResourceGroup

$spoke1network = Get-AzVirtualNetwork -Name $spoke1 -ResourceGroupName $spoke1resourceGroup
Write-Output "Lets create the peerings - 'Hub to Spoke1'"
# Peer Hub to Spoke1.
$peer1Name = $hubnetwork.name + "-to-" + $spoke1network.Name
Add-AzVirtualNetworkPeering -Name $peer1Name -VirtualNetwork $hubnetwork -RemoteVirtualNetworkId $spoke1network.Id -AllowGatewayTransit

Write-Output "Lets create the peering - 'Spoke1 to Hub'"
# Peer VNet2 to VNet1.
$peer2Name = $spoke1network.name + "-to-" + $hubnetwork.Name
Add-AzVirtualNetworkPeering -Name $peer2Name -VirtualNetwork $spoke1network -RemoteVirtualNetworkId $hubnetwork.Id -UseRemoteGateways