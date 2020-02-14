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

$virtualNetwork = New-AzVirtualNetwork -ResourceGroupName $rg -Location $location -Name myVirtualNetwork -AddressPrefix 10.0.0.0/16
$subnetConfig = Add-AzVirtualNetworkSubnetConfig -Name mySubnet -AddressPrefix 10.0.0.0/24 -PrivateEndpointNetworkPoliciesFlag "Disabled" -VirtualNetwork $virtualNetwork
$virtualNetwork | Set-AzVirtualNetwork

New-AzVm -ResourceGroupName $rg -Name "myVm" -Location $location -VirtualNetworkName "MyVirtualNetwork" -SubnetName "mySubnet" -SecurityGroupName "myNetworkSecurityGroup" -PublicIpAddressName "myPublicIpAddress" -OpenPorts 80,3389 -Credential $mycreds -AsJob

$server = New-AzSqlServer -ResourceGroupName $rg -ServerName $sqlServerName -Location $location -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))
New-AzSqlDatabase  -ResourceGroupName $rg -ServerName $sqlServerName -DatabaseName "mydb"-RequestedServiceObjectiveName "S0" -SampleName "AdventureWorksLT"

$privateEndpointConnection = New-AzPrivateLinkServiceConnection -Name "myConnection" -PrivateLinkServiceId $server.ResourceId -GroupId "sqlServer"
$virtualNetwork = Get-AzVirtualNetwork -ResourceGroupName  $rg -Name "MyVirtualNetwork"  
$subnet = $virtualNetwork | Select-object -ExpandProperty subnets | Where-Object  {$_.Name -eq 'mysubnet'}  
$privateEndpoint = New-AzPrivateEndpoint -ResourceGroupName $rg -Name "myPrivateEndpoint" -Location $location -Subnet  $subnet -PrivateLinkServiceConnection $privateEndpointConnection

$zone = New-AzPrivateDnsZone -ResourceGroupName $rg -Name $sqlDNSZoneName 
$link  = New-AzPrivateDnsVirtualNetworkLink -ResourceGroupName $rg -ZoneName $sqlDNSZoneName -Name "mylink" -VirtualNetworkId $virtualNetwork.Id  
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

Get-AzPublicIpAddress -Name myPublicIpAddress -ResourceGroupName $rg | Select-object IpAddress