$ErrorActionPreference = "silentlyContinue"

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

# Connect to Azure and get all VMs in a resource group
#Connect-AzAccount
# Select the Subscription to run the command against
#$sub = Select-AzSubscription -SubscriptionId "your_sub_id_here"

# Creating the HTML Header, and add document
# for cloud shell
#$filename = $HOME + "/audit-sample-" + ($subscriptions[$subscriptionChoice].Name)+".html"

$filename = "c:\temp\audit-sample-"+($subscriptions[$subscriptionChoice].Name)+".html"
Add-Content -Path $filename -Value `
('<h1>Azure Documentation - '+($subscriptions[$subscriptionChoice].Name)+'</h1>')

###
### VIRTUAL MACHINES
###

Add-Content -Path $filename -Value `
"<h2>Virtual Machines</h2>"

## Get all VMs from Azure
$vms = Get-AzVM -Status
$vmCount = $vms.Count
Write-host "Found $vmCount VMs "

## Add a table for VMs
## building Table header row
Add-Content -Path $filename -Value `
"<table border =""1""><tr><th>Name</th><th>Computer Name</th><th>Operating System</th><th>Disk Type</th><th>VM Size</th><th>VM State</th><th>Resource Group Name</th><th>Location</th><th>Interface Name</th></tr>"

## Values
$i=0
$vmProcessed = 1
Foreach ($vm in $vms) 
{
    Write-host 'Processing VM '$vmProcessed' of ' $vmCount
    #$vmName = $vm.NetworkInterfaceIDs
    $parts = ($vm.NetworkProfile.NetworkInterfaces.id).split("/")
    $nicLabel = $parts[8]
    $diskSKU = (Get-AzDisk -DiskName $VM.StorageProfile.OsDisk.Name).Sku.name
    $vmName = $vm.Name
    $vmComputername = $vm.OSProfile.ComputerName
    $vmOS = ($vm.StorageProfile.OsDisk.OsType).ToString()
    $vmSize = $vm.HardwareProfile.VmSize
    $vmPowerState = $vm.PowerState
    $vmResourceGroup = $vm.ResourceGroupName
    $vmLocation = $vm.Location
    Add-Content -Path $filename -Value `
    "<tr><td>$vmName</td><td>$vmComputername</td><td>$vmOS</td><td>$diskSKU</td><td>$vmSize</td><td>$vmPowerState</td><td>$vmResourceGroup</td><td>$vmLocation</td><td>$nicLabel</td></tr>"
    $i++
    Write-host 'Completed Processing VM '$vmProcessed' of ' $vmCount
    $vmProcessed++
}

### Close Table
Add-Content -Path $filename -Value "</table>"

########
######## NETWORK INTERFACE
########

Add-Content -Path $filename -Value `
"<h2>Network Interfaces</h2>"
$nics = Get-AzNetworkInterface 

Add-Content -Path $filename -Value `
"<table border =""1""><tr><th>Virtual Machine</th><th>Network Card Name</th><th>Resource Group Name</th><th>VNET</th><th>Subnet</th><th>Private IP Address</th><th>Private IP Allocation Method</th><th>Public IP Address</th><th>Public IP Allocation Method</th></tr>"

## Add a table for NICs
## building Table header row
## Write NICs to NIC table 
$i=0
$nicProcessed = 1
$nicCount = $nics.Count

Foreach ($nic in $nics) 
{
    Write-host 'Processing NIC '$nicProcessed' of ' $nicCount
    ## Get connected VM, if there is one connected to the network interface
    If (!$nic.VirtualMachine.id) 
    { 
        $vmLabel = " "
    }
    Else
    {
        $vmName = $nic.VirtualMachine.id
        $parts = $vmName.Split("/")
        $vmLabel = $parts[8]
    }

    #check for public ip
    $test = ($nic.IpConfigurations.PublicIpAddress.id)
    if ($test -eq $null)
    {
        $publicIP = "N/A"
        $publicIPAllocationMethod = "N/A"
    }
    else 
    {
        $publicIP = (Get-AzPublicIpAddress -name ($nic.IpConfigurations.PublicIpAddress.id).split("/")[8]).ipaddress
        $publicIPAllocationMethod = (Get-AzPublicIpAddress -Name ($nic.IpConfigurations.PublicIpAddress.id).Split('/')[8]).PublicIpAllocationMethod
    }

## GET VNET and SUBNET

    $networkConfig = $nic.IPconfigurations.subnet.id
    $parts = $networkConfig.Split("/")
    $vnetName = $parts[8]
    $subnetName = $parts[10]
    $nicName = $nic.Name
    $nicResourceGroupName = $nic.ResourceGroupName
    $nicPriavteIP = ($nic.IPconfigurations | Where-Object {$_.Primary -eq "True"}).PrivateIpAddress
    ##$nicPriavteIP = $nic.IPconfigurations.PrivateIpAddress for all ips including secondary ips
    $nicPrivateIPAllocationMethod = ($nic.IPconfigurations | Where-Object {$_.Primary -eq "True"}).PrivateIpAllocationMethod
    Add-Content -Path $filename -Value `
    "<tr><td>$vmLabel</td><td>$nicName</td><td>$nicResourceGroupName</td><td>$vnetName</td><td>$subnetName</td><td>$nicPriavteIP</td><td>$nicPrivateIPAllocationMethod</td><td>$publicIP</td><td>$publicIPAllocationMethod</td></tr>"
    $i++
    Write-host 'Completed Processing NIC '$nicProcessed' of ' $nicCount
    $nicProcessed++
}

### Close Table
Add-Content -Path $filename -Value "</table>"

########
######## Create a table for NSG
########

Add-Content -Path $filename -Value `
"<h2>Network Security Group </h2>"

########
######## Create a table for each NSG
########

### Get all NSGs
$nsgs = Get-AzNetworkSecurityGroup


ForEach ($nsg in $nsgs) 
{
    $nsgName = $nsg.Name
    Add-Content -Path $filename -Value `
    "<h2>$nsgName</h2>"

    Add-Content -Path $filename -Value `
    "<table border =""1"">
    <tr>
    <th>Rule Name</th>
    <th>Protocol</th>
    <th>Source Port Range</th>
    <th>Destination Port Range</th>
    <th>Source Address Prefix</th>
    <th>Destination Address Prefix</th>
    <th>Access</th>
    <th>Priority</th>
    <th>Direction</th></tr>"

    ##get nsg rulesets
    $defaultNSGRuleConfig = ((Get-AzNetworkSecurityGroup -Name $nsg.Name -ResourceGroupName $nsg.ResourceGroupName).DefaultSecurityRules) | Select-Object Name,Description,Priority,Protocol,Access,Direction,@{Name=’SourceAddressPrefix’;Expression={[string]::join(“,”, ($_.SourceAddressPrefix))}},@{Name=’SourcePortRange’;Expression={[string]::join(“,”, ($_.SourcePortRange))}},@{Name=’DestinationAddressPrefix’;Expression={[string]::join(“,”, ($_.DestinationAddressPrefix))}},@{Name=’DestinationPortRange’;Expression={[string]::join(“,”, ($_.DestinationPortRange))}}
    $customNSGRuleConfig = (Get-AzNetworkSecurityGroup -Name $nsg.Name -ResourceGroupName $nsg.ResourceGroupName).SecurityRules  | Select-Object Name,Description,Priority,Protocol,Access,Direction,@{Name=’SourceAddressPrefix’;Expression={[string]::join(“,”, ($_.SourceAddressPrefix))}},@{Name=’SourcePortRange’;Expression={[string]::join(“,”, ($_.SourcePortRange))}},@{Name=’DestinationAddressPrefix’;Expression={[string]::join(“,”, ($_.DestinationAddressPrefix))}},@{Name=’DestinationPortRange’;Expression={[string]::join(“,”, ($_.DestinationPortRange))}}

    $i = 0 

    foreach ($defaultRule in $defaultNSGRuleConfig)
    {
        $defaultNSGRuleName = $defaultRule.Name
        $defaultNSGRuleProtocol = $defaultRule.Protocol
        $defaultNSGRuleSourcePortRange = $defaultRule.SourcePortRange
        $defaultNSGRuleDestinationPortRange = $defaultRule.DestinationPortRange
        $defaultNSGRuleSourceAddressPrefix = $defaultRule.SourceAddressPrefix
        $defaultNSGRuleDestinationAddressPrefix= $defaultRule.DestinationAddressPrefix
        $defaultNSGRuleAccess = $defaultRule.Access
        $defaultNSGRulePriority = [string]$defaultRule.Priority
        $defaultNSGRuleDirection = $defaultRule.Direction

        Add-Content -Path $filename -Value `
        "<tr>
        <td>$defaultNSGRuleName</td>
        <td>$defaultNSGRuleProtocol</td>
        <td>$defaultNSGRuleSourcePortRange</td>
        <td>$defaultNSGRuleDestinationPortRange</td>
        <td>$defaultNSGRuleSourceAddressPrefix</td>
        <td>$defaultNSGRuleDestinationAddressPrefix</td>
        <td>$defaultNSGRuleAccess</td>
        <td>$defaultNSGRulePriority</td>
        <td>$defaultNSGRuleDirection</td>
        </tr>"    

        $i++
    }
    foreach ($customRule in $customNSGRuleConfig)
    {
        $customRuleName = $customRule.Name
        $customRuleProtocol = $customRule.Protocol
        $customRuleSourcePortRange = $customRule.SourcePortRange
        $customRuleDestinationPortRange = $customRule.DestinationPortRange
        $customRuleSourceAddressPrefix = $customRule.SourceAddressPrefix
        $customRuleDestinationAddressPrefix= $customRule.DestinationAddressPrefix
        $customRuleAccess = $customRule.Access
        $customRulePriority = [string]$customRule.Priority
        $customRuleDirection = $customRule.Direction
      
        Add-Content -Path $filename -Value `
        "<tr>
        <td>$customRuleName</td>
        <td>$customRuleProtocol</td>
        <td>$customRuleSourcePortRange</td>
        <td>$customRuleDestinationPortRange</td>
        <td>$customRuleSourceAddressPrefix</td>
        <td>$customRuleDestinationAddressPrefix</td>
        <td>$customRuleAccess</td>
        <td>$customRulePriority</td>
        <td>$customRuleDirection</td>
        </tr>"  

        $i++
    }
    ### Close Table
    Add-Content -Path $filename -Value "</table>"
}

###
### Web Apps
###

Add-Content -Path $filename -Value `
"<h2>App Service Plans</h2>"

## Get all App Service Plans from Azure
$appServicePlans = Get-AzAppServicePlan

## Add a table for App Service Plans
## building Table header row
Add-Content -Path $filename -Value `
"<table border =""1""><tr><th>Name</th><th>Location</th><th>Resource Group Name</th><th>SKU</th><th>Kind</th><th>Number Of Sites</th><th>Status</th></tr>"

## Values
$i=0
Foreach ($asp in $appServicePlans) 
{
  $aspName = $asp.Name
  $aspSKU = $asp.SKU.Name
  $aspResourceGroup = $asp.ResourceGroup
  $aspLocation = $asp.Location 
  $aspKind = $asp.Kind
  $aspSiteCount = $asp.NumberOfSites
  $aspStatus = $asp.Status

  Add-Content -Path $filename -Value `
  "<tr><td>$aspName</td><td>$aspLocation</td><td>$aspResourceGroup</td><td>$aspSKU</td><td>$aspKind</td><td>$aspSiteCount</td><td>$aspStatus</td></tr>"

  $i++

}

### Close Table
Add-Content -Path $filename -Value "</table>"

Foreach ($asp in $appServicePlans) 
{
  $webApps=Get-AzWebApp -AppServicePlan $asp
  foreach ($webApp in $webApps)
  {
    $webAppName = $webApp.Name
    $webAppResourceGroup = ($webApp.id).Split("/")[4]
    $webAppKind = $webApp.Kind
    $webAppHostName = $webApp.Hostnames
    $webAppState = $webApp.State
    $aspRG = ($asp.id).Split("/")[4]
    
    Add-Content -Path $filename -Value `
    "<h3>$webAppName</h3>"
    Add-Content -Path $filename -Value `
    "<table border =""1""><tr><th>Name</th><th>Service Plan Resource Group Name</th><th>App Resource Group Name</th><th>Kind</th><th>URL</th><th>Status</th></tr>"
    ## adding headings for each App Service Plan
    Add-Content -Path $filename -Value `
    "<tr><td>$webAppName</td><td>$aspRG</td><td>$webAppResourceGroup</td><td>$webAppKind</td><td>$webAppHostName</td><td>$webAppState</td></tr>"
    Add-Content -Path $filename -Value "</table>"
  }  
}

### Close Table
Add-Content -Path $filename -Value "</table>"