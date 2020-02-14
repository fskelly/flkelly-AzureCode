$vpnResourceGroup = $(jq -r '.VPN.vpnResourceGroup' settings.json)
$spoke3 = $(jq -r '.NESpoke1.Name' settings.json) 
$spoke3addressRange = $(jq -r '.NESpoke1.addressSpace' settings.json) 
$spoke3subnet = $(jq -r '.NESpoke1.addressRange' settings.json)  
$spoke3location = $(jq -r '.NESpoke1.location' settings.json)  
$spoke3resourceGroup = (jq -r '.NESpoke1.resourceGroup' settings.json) 
Write-Output "Creating required subnets for NEU Spoke"
$spsubnet3= New-AzVirtualNetworkSubnetConfig -Name $spoke3 -AddressPrefix $spoke3Subnet
Write-Output "Creating VNets with subnets associated to them"
New-AzVirtualNetwork -Name $spoke3 -ResourceGroupName $spoke3resourceGroup -Location $spoke3location -AddressPrefix $spoke3addressRange -Subnet $spsubnet3

$hubVNetName = $(jq -r '.VPN.hubVnetName' settings.json)
$hubnetwork = Get-AzVirtualNetwork -Name $hubVNetName -ResourceGroupName $vpnResourceGroup

$spoke3network = Get-AzVirtualNetwork -Name $spoke3 -ResourceGroupName $spoke3resourceGroup
Write-Output "Lets create the peerings - 'Hub to Spoke3'"
# Peer Hub to Spoke1.
$peer1Name = $hubnetwork.name + "-to-" + $spoke3network.Name
Add-AzVirtualNetworkPeering -Name $peer1Name -VirtualNetwork $hubnetwork -RemoteVirtualNetworkId $spoke3network.Id -AllowGatewayTransit

Write-Output "Lets create the peering - 'Spoke3 to Hub'"
# Peer VNet2 to VNet1.
$peer2Name = $spoke3network.name + "-to-" + $hubnetwork.Name
Add-AzVirtualNetworkPeering -Name $peer2Name -VirtualNetwork $spoke3network -RemoteVirtualNetworkId $hubnetwork.Id -UseRemoteGateways