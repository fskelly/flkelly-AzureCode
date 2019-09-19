#$ErrorActionPreference = "silentlyContinue"

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
$filename = "c:\temp\vms-sample-"+($subscriptions[$subscriptionChoice].Name)+".html"
Add-Content -Path $filename -Value `
('<h1>Azure Documentation - '+($subscriptions[$subscriptionChoice].Name)+'</h1>')

###
### VIRTUAL MACHINES
###

Add-Content -Path $filename -Value `
"<h2>Virtual Machines</h2>"

## Get all VMs from Azure
$vms = Get-AzVM -Status

## Add a table for VMs
## building Table header row
Add-Content -Path $filename -Value `
"<table border =""1""><tr><th>Name</th><th>Computer Name</th><th>Operating System</th><th>Disk Type</th><th>VM Size</th><th>VM State</th><th>Resource Group Name</th><th>Location</th><th>Interface Name</th></tr>"

## Values
$i=0
Foreach ($vm in $vms) 
{
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
}

### Close Table
Add-Content -Path $filename -Value "</table>"