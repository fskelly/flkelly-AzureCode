#Windows VMs
Write-Output "Creating WEU Spoke VMs"

$winVmCount = 1
if ($winVmCount -gt 0)
{
  For ($i=0; $i -le ($winVmCount-1); $i++) 
  {
      #change as needed, the next 2 lines
      $VMLocalAdminUser = "LocalAdminUser"
      $VMLocalAdminSecurePassword = ConvertTo-SecureString ''PASSWORD'' -AsPlainText -Force
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