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

# Connect to Azure and get all NICs in a resource group
#Connect-AzAccount
# Select the Subscription to run the command against
#$sub = Select-AzSubscription -SubscriptionId "your_sub_id_here"

# Creating the HTML Header, and add document
$filename = "c:\temp\nics-sample-"+($subscriptions[$subscriptionChoice].Name)+".html"


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
Foreach ($nic in $nics) 
{
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
}

### Close Table
Add-Content -Path $filename -Value "</table>"