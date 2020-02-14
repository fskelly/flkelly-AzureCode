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

Write-Output "Creating Azure Resource Groups"
# Create as many resource groups as you needs. This is my naming convention.
$rgsToCreate = "flkelly-zan-net-dev","flkelly-zan-vms-dev","flkelly-weu-net-dev","flkelly-weu-vms-dev","flkelly-weu-monitor-dev","flkelly-neu-net-dev","flkelly-neu-vms-dev"
foreach ($rg in $rgsToCreate)
{
  $region = $rg.Substring(8,3)
  Write-Output "Creating $rg Resource Group"
  switch ($region) 
  {
    "zan" { $rgLocation = "SouthAfricaNorth" }
    "weu" { $rgLocation = "WestEurope" }
    "neu" { $rgLocation = "NorthEurope" }
    Default { $rgLocation = "SouthAfricaNorth" }

  }
  New-AzResourceGroup -Name $rg -Location $rgLocation
}

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
#you can comment this section out if you do not want/need the vpn
Write-Output "Creating Virtual network gateway and connections"
Write-Output "This might take a while, grab some coffee :)"
$vnetGW = $hubVNetName + "-to-" + $onPremRange.Substring(0,$onPremRange.Length-3)
New-AzVirtualNetworkGateway -Name $vnetGW -ResourceGroupName $vpnResourceGroup -Location $vpnLocation -IpConfigurations $gwipconfig -GatewayType Vpn -VpnType RouteBased -GatewaySku Basic
$gateway1 = Get-AzVirtualNetworkGateway -Name $vnetGW -ResourceGroupName $vpnResourceGroup
$local = Get-AzLocalNetworkGateway -Name $localNetworkGatewayName -ResourceGroupName $vpnResourceGroup
$connectionName = $onPremRange.Substring(0,$onPremRange.Length-3) + "-to-" + $hubVNet.Name
New-AzVirtualNetworkGatewayConnection -Name $connectionName -ResourceGroupName $vpnResourceGroup -Location $vpnLocation -VirtualNetworkGateway1 $gateway1 -LocalNetworkGateway2 $local -ConnectionType IPsec -RoutingWeight 10 -SharedKey $presharedKey

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

#Windows VMs
Write-Output "Creating ZAN Spoke VMs"

$winVmCount = 1
if ($winVmCount -gt 0)
{
  For ($i=0; $i -le ($winVmCount-1); $i++) 
  {
      #change as needed, the next 2 lines
      $VMLocalAdminUser = "LocalAdminUser"
      $VMLocalAdminSecurePassword = ConvertTo-SecureString '84608juewt_($*^)(' -AsPlainText -Force
      $VMSize = "Standard_b1s"
      $vmsRG = $(jq -r '.ZASpoke1VMs.resourceGroup' settings.json) 
      #$vmsRG = "flkelly-weu-vms"
      $vmsloc = $(jq -r '.ZASpoke1VMs.location' settings.json) 
      $vnetname = $(jq -r '.ZASpoke1.Name' settings.json) 
      $vnetRG = $(jq -r '.ZASpoke1.resourceGroup' settings.json) 
      $subnetname = $(jq -r '.ZASpoke1.Name' settings.json)
      $vmLocation = $(jq -r '.ZASpoke1VMs.location' settings.json) 
      $vmRegion = $(jq -r '.ZASpoke1VMs.prefix' settings.json) 
      $vnet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $vnetRG
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetname -VirtualNetwork $vnet | Where-Object { $_.Name -ne "GatewaySubnet" }
      $vmnumber = $i+1
      write-host $vmname
      $VMName = "$vmRegion-s-win$vmnumber"
      $NICName = $VMName + "-NIC"
      $NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $vmsRG -Location $vmLocation -SubnetId $subnet.Id
      $vmResourceGroup = "flkelly-$vmRegion-vms"
      write-output "Creating $VMName with $NICName"
      $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
      $Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
      $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
      $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
      $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2012-R2-Datacenter' -Version latest
      Set-AzVMBootDiagnostics -Disable -VM $VirtualMachine
      New-AzVM -ResourceGroupName $vmsRG -Location $vmLocation -VM $VirtualMachine -Verbose
      #$VirtualMachine
  }
}
else 
{
  Write-host "Not deploying Windows VM - SKIPPED"
}

$linuxVmCount = 1
if ($linuxVmCount -gt 0)
{
  For ($i=0; $i -le ($linuxVmCount-1); $i++) 
  {
      $VMLocalAdminUser = "LocalAdminUser"
      $VMLocalAdminSecurePassword = ConvertTo-SecureString 'TEstPassword1205jfkjgeYT3U' -AsPlainText -Force
      $VMSize = "Standard_b1s"
      $vmsRG = $(jq -r '.ZASpoke1VMs.resourceGroup' settings.json) 
      #$vmsRG = "flkelly-ZANu-vms"
      $vmsloc = $(jq -r '.ZASpoke1VMs.location' settings.json) 
      $vnetname = $(jq -r '.ZASpoke1.Name' settings.json) 
      $vnetRG = $(jq -r '.ZASpoke1.resourceGroup' settings.json) 
      $subnetname = $(jq -r '.ZASpoke1.Name' settings.json)
      $vmLocation = $(jq -r '.ZASpoke1VMs.location' settings.json) 
      $vmRegion = $(jq -r '.ZASpoke1VMs.prefix' settings.json) 
      $vnet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $vnetRG
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetname -VirtualNetwork $vnet | Where-Object { $_.Name -ne "GatewaySubnet" }
      $vmnumber = $i+1
      write-host $vmname
      $VMName = "$vmRegion-s-linux$vmnumber"
      $NICName = $VMName + "-NIC"
      $NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $vmsRG -Location $vmLocation -SubnetId $subnet.Id
      $vmResourceGroup = "flkelly-$vmRegion-vms"
      write-output "Creating $VMName with $NICName"
      $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
      $Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
      $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName $VMName -Credential $Credential #-DisablePasswordAuthentication , at present issue with this
      $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
      $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'Canonical' -Offer 'UbuntuServer' -Skus '14.04.2-LTS' -Version latest
      Set-AzVMBootDiagnostics -Disable -VM $VirtualMachine
      #ssh-keygen -N $VMLocalAdminSecurePassword -f $HOME/clouddrive/azuresshkey
      #$sshPublicKey = get-content $HOME/clouddrive/azuresshkey.pub
      #Add-AzVMSshPublicKey -VM $vmconfig -KeyData $sshPublicKey -Path $HOME/.ssh/authorized_keys
      #$sshPublicKey = cat ~/.ssh/id_rsa.pub
      #Add-AzVMSshPublicKey -VM $VirtualMachine -KeyData $sshPublicKey -Path "/home/azureuser/.ssh/authorized_keys"
      New-AzVM -ResourceGroupName $vmsRG -Location $vmLocation -VM $VirtualMachine -Verbose
      #$VirtualMachine
  }
}
else 
{
  Write-host "Not deploying Linux VM - SKIPPED"
}

#Windows VMs
Write-Output "Creating WEU Spoke VMs"

$winVmCount = 1
if ($winVmCount -gt 0)
{
  For ($i=0; $i -le ($winVmCount-1); $i++) 
  {
      #change as needed, the next 2 lines
      $VMLocalAdminUser = "LocalAdminUser"
      $VMLocalAdminSecurePassword = ConvertTo-SecureString '84608juewt_($*^)(' -AsPlainText -Force
      $VMSize = "Standard_b1s"
      $vmsRG = $(jq -r '.WESpoke1VMs.resourceGroup' settings.json) 
      #$vmsRG = "flkelly-weu-vms"
      $vmsloc = $(jq -r '.WESpoke1VMs.location' settings.json) 
      $vnetname = $(jq -r '.WESpoke1.Name' settings.json) 
      $vnetRG = $(jq -r '.WESpoke1.resourceGroup' settings.json) 
      $subnetname = $(jq -r '.WESpoke1.Name' settings.json)
      $vmLocation = $(jq -r '.WESpoke1VMs.location' settings.json) 
      $vmRegion = $(jq -r '.WESpoke1VMs.prefix' settings.json) 
      $vnet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $vnetRG
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetname -VirtualNetwork $vnet | Where-Object { $_.Name -ne "GatewaySubnet" }
      $vmnumber = $i+1
      write-host $vmname
      $VMName = "$vmRegion-s-win$vmnumber"
      $NICName = $VMName + "-NIC"
      $NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $vmsRG -Location $vmLocation -SubnetId $subnet.Id
      $vmResourceGroup = "flkelly-$vmRegion-vms"
      write-output "Creating $VMName with $NICName"
      $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
      $Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
      $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
      $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
      Set-AzVMBootDiagnostics -Disable -VM $VirtualMachine
      $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2012-R2-Datacenter' -Version latest
      New-AzVM -ResourceGroupName $vmsRG -Location $vmLocation -VM $VirtualMachine -Verbose
      #$VirtualMachine
  }
}
else 
{
  Write-host "Not deploying Windows VM - SKIPPED"
}

$linuxVmCount = 1
if ($linuxVmCount -gt 0)
{
  For ($i=0; $i -le ($linuxVmCount-1); $i++) 
  {
      $VMLocalAdminUser = "LocalAdminUser"
      $VMLocalAdminSecurePassword = ConvertTo-SecureString 'TEstPassword1205jfkjgeYT3U' -AsPlainText -Force
      $VMSize = "Standard_b1s"
      $vmsRG = $(jq -r '.WESpoke1VMs.resourceGroup' settings.json) 
      #$vmsRG = "flkelly-weu-vms"
      $vmsloc = $(jq -r '.WESpoke1VMs.location' settings.json) 
      $vnetname = $(jq -r '.WESpoke1.Name' settings.json) 
      $vnetRG = $(jq -r '.WESpoke1.resourceGroup' settings.json) 
      $subnetname = $(jq -r '.WESpoke1.Name' settings.json)
      $vmLocation = $(jq -r '.WESpoke1VMs.location' settings.json) 
      $vmRegion = $(jq -r '.WESpoke1VMs.prefix' settings.json) 
      $vnet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $vnetRG
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetname -VirtualNetwork $vnet | Where-Object { $_.Name -ne "GatewaySubnet" }
      $vmnumber = $i+1
      write-host $vmname
      $VMName = "$vmRegion-s-linux$vmnumber"
      $NICName = $VMName + "-NIC"
      $NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $vmsRG -Location $vmLocation -SubnetId $subnet.Id
      $vmResourceGroup = "flkelly-$vmRegion-vms"
      write-output "Creating $VMName with $NICName"
      $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
      $Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
      $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName $VMName -Credential $Credential #-DisablePasswordAuthentication , at present issue with this
      $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
      Set-AzVMBootDiagnostics -Disable -VM $VirtualMachine
      $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'Canonical' -Offer 'UbuntuServer' -Skus '14.04.2-LTS' -Version latest
      #ssh-keygen -N $VMLocalAdminSecurePassword -f $HOME/clouddrive/azuresshkey
      #$sshPublicKey = get-content $HOME/clouddrive/azuresshkey.pub
      #Add-AzVMSshPublicKey -VM $vmconfig -KeyData $sshPublicKey -Path $HOME/.ssh/authorized_keys
      #$sshPublicKey = cat ~/.ssh/id_rsa.pub
      #Add-AzVMSshPublicKey -VM $VirtualMachine -KeyData $sshPublicKey -Path "/home/azureuser/.ssh/authorized_keys"
      New-AzVM -ResourceGroupName $vmsRG -Location $vmLocation -VM $VirtualMachine -Verbose
      #$VirtualMachine
  }
}
else 
{
  Write-host "Not deploying Linux VM - SKIPPED"
}

#Windows VMs
Write-Output "Creating NEU Spoke VMs"

$winVmCount = 1
if ($winVmCount -gt 0)
{
  For ($i=0; $i -le ($winVmCount-1); $i++) 
  {
      #change as needed, the next 2 lines
      $VMLocalAdminUser = "LocalAdminUser"
      $VMLocalAdminSecurePassword = ConvertTo-SecureString '84608juewt_($*^)(' -AsPlainText -Force
      $VMSize = "Standard_b1s"
      $vmsRG = $(jq -r '.NESpoke1VMs.resourceGroup' settings.json) 
      #$vmsRG = "flkelly-weu-vms"
      $vmsloc = $(jq -r '.NESpoke1VMs.location' settings.json) 
      $vnetname = $(jq -r '.NESpoke1.Name' settings.json) 
      $vnetRG = $(jq -r '.NESpoke1.resourceGroup' settings.json) 
      $subnetname = $(jq -r '.NESpoke1.Name' settings.json)
      $vmLocation = $(jq -r '.NESpoke1VMs.location' settings.json) 
      $vmRegion = $(jq -r '.NESpoke1VMs.prefix' settings.json) 
      $vnet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $vnetRG
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetname -VirtualNetwork $vnet | Where-Object { $_.Name -ne "GatewaySubnet" }
      $vmnumber = $i+1
      write-host $vmname
      $VMName = "$vmRegion-s-win$vmnumber"
      $NICName = $VMName + "-NIC"
      $NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $vmsRG -Location $vmLocation -SubnetId $subnet.Id
      $vmResourceGroup = "flkelly-$vmRegion-vms"
      write-output "Creating $VMName with $NICName"
      $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
      $Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
      $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $VMName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
      $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
      Set-AzVMBootDiagnostics -Disable -VM $VirtualMachine
      $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2012-R2-Datacenter' -Version latest
      New-AzVM -ResourceGroupName $vmsRG -Location $vmLocation -VM $VirtualMachine -Verbose
      #$VirtualMachine
  }
}
else 
{
  Write-host "Not deploying Windows VM - SKIPPED"
}

$linuxVmCount = 1
if ($linuxVmCount -gt 0)
{
  For ($i=0; $i -le ($linuxVmCount-1); $i++) 
  {
      $VMLocalAdminUser = "LocalAdminUser"
      $VMLocalAdminSecurePassword = ConvertTo-SecureString 'TEstPassword1205jfkjgeYT3U' -AsPlainText -Force
      $VMSize = "Standard_b1s"
      $vmsRG = $(jq -r '.NESpoke1VMs.resourceGroup' settings.json) 
      #$vmsRG = "flkelly-weu-vms"
      $vmsloc = $(jq -r '.NESpoke1VMs.location' settings.json) 
      $vnetname = $(jq -r '.NESpoke1.Name' settings.json) 
      $vnetRG = $(jq -r '.NESpoke1.resourceGroup' settings.json) 
      $subnetname = $(jq -r '.NESpoke1.Name' settings.json)
      $vmLocation = $(jq -r '.NESpoke1VMs.location' settings.json) 
      $vmRegion = $(jq -r '.NESpoke1VMs.prefix' settings.json) 
      $vnet = Get-AzVirtualNetwork -Name $vnetname -ResourceGroupName $vnetRG
      $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetname -VirtualNetwork $vnet | Where-Object { $_.Name -ne "GatewaySubnet" }
      $vmnumber = $i+1
      write-host $vmname
      $VMName = "$vmRegion-s-linux$vmnumber"
      $NICName = $VMName + "-NIC"
      $NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $vmsRG -Location $vmLocation -SubnetId $subnet.Id
      $vmResourceGroup = "flkelly-$vmRegion-vms"
      write-output "Creating $VMName with $NICName"
      $VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
      $Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
      $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Linux -ComputerName $VMName -Credential $Credential #-DisablePasswordAuthentication , at present issue with this
      $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
      Set-AzVMBootDiagnostics -Disable -VM $VirtualMachine
      $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName 'Canonical' -Offer 'UbuntuServer' -Skus '14.04.2-LTS' -Version latest
      #ssh-keygen -N $VMLocalAdminSecurePassword -f $HOME/clouddrive/azuresshkey
      #$sshPublicKey = get-content $HOME/clouddrive/azuresshkey.pub
      #Add-AzVMSshPublicKey -VM $vmconfig -KeyData $sshPublicKey -Path $HOME/.ssh/authorized_keys
      #$sshPublicKey = cat ~/.ssh/id_rsa.pub
      #Add-AzVMSshPublicKey -VM $VirtualMachine -KeyData $sshPublicKey -Path "/home/azureuser/.ssh/authorized_keys"
      New-AzVM -ResourceGroupName $vmsRG -Location $vmLocation -VM $VirtualMachine -Verbose
      #$VirtualMachine
  }
}
else 
{
  Write-host "Not deploying Linux VM - SKIPPED"
}