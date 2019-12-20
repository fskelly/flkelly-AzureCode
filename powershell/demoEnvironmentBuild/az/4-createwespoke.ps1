$vpnResourceGroup = $(jq -r '.VPN.vpnResourceGroup' settings.json)
$spoke2 = $(jq -r '.WESpoke1.Name' settings.json) 
$spoke2addressRange = $(jq -r '.WESpoke1.addressSpace' settings.json) 
$spoke2subnet = $(jq -r '.WESpoke1.addressRange' settings.json)  
$spoke2location = $(jq -r '.WESpoke1.location' settings.json)  
$spoke2resourceGroup = (jq -r '.WESpoke1.resourceGroup' settings.json) 
Write-Output "Creating required subnets for WEU Spoke"
$spsubnet2= New-AzVirtualNetworkSubnetConfig -Name $spoke2 -AddressPrefix $spoke2Subnet
Write-Output "Creating VNets with subnets associated to them"
New-AzVirtualNetwork -Name $spoke2 -ResourceGroupName $spoke2resourceGroup -Location $spoke2location -AddressPrefix $spoke2addressRange -Subnet $spsubnet2

$hubVNetName = $(jq -r '.VPN.hubVnetName' settings.json)
$hubnetwork = Get-AzVirtualNetwork -Name $hubVNetName -ResourceGroupName $vpnResourceGroup

$spoke2network = Get-AzVirtualNetwork -Name $spoke2 -ResourceGroupName $spoke2resourceGroup
Write-Output "Lets create the peerings - 'Hub to Spoke2'"
# Peer Hub to Spoke1.
$peer1Name = $hubnetwork.name + "-to-" + $spoke2network.Name
Add-AzVirtualNetworkPeering -Name $peer1Name -VirtualNetwork $hubnetwork -RemoteVirtualNetworkId $spoke2network.Id -AllowGatewayTransit

Write-Output "Lets create the peering - 'Spoke1 to Hub'"
# Peer VNet2 to VNet1.
$peer2Name = $spoke2network.name + "-to-" + $hubnetwork.Name
Add-AzVirtualNetworkPeering -Name $peer2Name -VirtualNetwork $spoke2network -RemoteVirtualNetworkId $hubnetwork.Id -UseRemoteGateways