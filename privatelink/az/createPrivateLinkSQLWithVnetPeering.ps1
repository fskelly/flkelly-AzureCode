#adapted from https://docs.microsoft.com/en-us/azure/private-link/create-private-link-service-powershell


$location = "westeurope"

switch ($location)
{
    "westus"
    {
        $loc = "wus"
    }
    "eastus"
    {
        $loc = "eus"
    }
    "westeurope"
    {
        $loc = "weu"
    }
    "southafricanorth"
    {
        $loc = "zan"
    }
}

Install-Module -Name Az.PrivateDns -force
#update as needed
$adminSqlLogin = ""
$password = ""

$secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
$mycreds = New-Object System.Management.Automation.PSCredential ($adminSqlLogin, $secpasswd)

$rg = "$loc-pvtlink1"
$sqlServerName = "$loc-sql1flkelly"
$dnsSuffix = ".pvtlink.fsk"
$dnsZoneName = "$loc-pvtlink-zone$dnsSuffix"
$sqlDNSZoneName = $sqlServerName + $dnsSuffix


New-AzResourceGroup -ResourceGroupName $rg -Location $location

## VM Subnet
$vmVirtualNetwork = New-AzVirtualNetwork -ResourceGroupName $rg -Location $location -Name vmVirtualNetwork -AddressPrefix 10.0.0.0/16
$vmSubnetConfig = Add-AzVirtualNetworkSubnetConfig -Name vmSubnet -AddressPrefix 10.0.0.0/24 -PrivateEndpointNetworkPoliciesFlag "Disabled" -VirtualNetwork $vmVirtualNetwork
$vmVirtualNetwork | Set-AzVirtualNetwork

New-AzVm -ResourceGroupName $rg -Name "myVm" -Location $location -VirtualNetworkName "vmVirtualNetwork" -SubnetName "vmSubnet" -SecurityGroupName "vmNetworkSecurityGroup" -PublicIpAddressName "vmPublicIpAddress" -OpenPorts 80,3389 -Credential $mycreds -AsJob

##Private Link Subnet
$pvtlinkVirtualNetwork = New-AzVirtualNetwork -ResourceGroupName $rg -Location $location -Name pvtlinkVirtualNetwork -AddressPrefix 192.168.0.0/16
$pvtlinkSubnetConfig = Add-AzVirtualNetworkSubnetConfig -Name pvtlinkSubnet -AddressPrefix 192.168.0.0/24 -PrivateEndpointNetworkPoliciesFlag "Disabled" -VirtualNetwork $pvtlinkVirtualNetwork
$pvtlinkVirtualNetwork | Set-AzVirtualNetwork

$server = New-AzSqlServer -ResourceGroupName $rg -ServerName $sqlServerName -Location $location -SqlAdministratorCredentials $mycreds
New-AzSqlDatabase  -ResourceGroupName $rg -ServerName $sqlServerName -DatabaseName "mydb"-RequestedServiceObjectiveName "S0" -SampleName "AdventureWorksLT"

$privateEndpointConnection = New-AzPrivateLinkServiceConnection -Name "myConnection" -PrivateLinkServiceId $server.ResourceId -GroupId "sqlServer"
$virtualNetwork = Get-AzVirtualNetwork -ResourceGroupName  $rg -Name "pvtlinkVirtualNetwork"
$virtualNetwork1 = Get-AzVirtualNetwork -ResourceGroupName  $rg -Name "vmVirtualNetwork"  

$subnet = $virtualNetwork | Select-object -ExpandProperty subnets | Where-Object  {$_.Name -eq 'pvtlinkSubnet'}  
$privateEndpoint = New-AzPrivateEndpoint -ResourceGroupName $rg -Name "myPrivateEndpoint" -Location $location -Subnet  $subnet -PrivateLinkServiceConnection $privateEndpointConnection

$zone = New-AzPrivateDnsZone -ResourceGroupName $rg -Name $dnsZoneName 
$link1  = New-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $rg -ZoneName $dnsZoneName -Name "pvtlink" -VirtualNetworkId $virtualNetwork.Id
$link2  = New-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $rg -ZoneName $dnsZoneName -Name "vmlink" -VirtualNetworkId $virtualNetwork1.Id

$networkInterface = Get-AzResource -ResourceId $privateEndpoint.NetworkInterfaces[0].Id -ApiVersion "2019-04-01" 
foreach ($ipconfig in $networkInterface.properties.ipConfigurations) 
{ 
    foreach ($fqdn in $ipconfig.properties.privateLinkConnectionProperties.fqdns) 
    { 
        Write-Host "$($ipconfig.properties.privateIPAddress) $($fqdn)"  
        $recordName = $fqdn.split('.',2)[0] 
        $dnsZone = $fqdn.split('.',2)[1] 
        New-AzPrivateDnsRecordSet -Name $recordName -RecordType A -ZoneName $dnsZoneName -ResourceGroupName $rg -Ttl 600 -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address $ipconfig.properties.privateIPAddress)  
    }       
}

#peering the vmnetwork and pvtlink network
$peer1Name = $vmVirtualNetwork.name + "-to-" + $pvtlinkVirtualNetwork.Name
Add-AzVirtualNetworkPeering -Name $peer1Name -VirtualNetwork $vmVirtualNetwork -RemoteVirtualNetworkId $pvtlinkVirtualNetwork.Id
$peer2Name = $pvtlinkVirtualNetwork.Name + "-to-" + $vmVirtualNetwork.name
Add-AzVirtualNetworkPeering -Name $peer2Name -VirtualNetwork $pvtlinkVirtualNetwork -RemoteVirtualNetworkId $vmVirtualNetwork.Id

Get-AzPublicIpAddress -Name vmPublicIpAddress -ResourceGroupName $rg | Select-object IpAddress