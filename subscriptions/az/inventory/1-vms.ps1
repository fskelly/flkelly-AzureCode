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

# Creating the Word Object, set Word to visual and add document
$Word = New-Object -ComObject Word.Application
$Word.Visible = $True
$Document = $Word.Documents.Add()
$Selection = $Word.Selection

## Add some text to start with
$Selection.Style = 'Title'
$Selection.TypeText("Azure Documentation - "  + $subscriptions[$subscriptionChoice].Name)
$Selection.TypeParagraph()

### Add the TOC
$range = $Selection.Range
$toc = $Document.TablesOfContents.Add($range)
$Selection.TypeParagraph()

###
### VIRTUAL MACHINES
###

## Add some text
$Selection.Style = 'Heading 1'
$Selection.TypeText("Virtual Machines")
$Selection.TypeParagraph()

## Get all VMs from Azure
$vms = Get-AzVM -Status

## Add a table for VMs
$vmTable = $Selection.Tables.add($Word.Selection.Range, $VMs.Count + 2, 9,
[Microsoft.Office.Interop.Word.WdDefaultTableBehavior]::wdWord9TableBehavior,
[Microsoft.Office.Interop.Word.WdAutoFitBehavior]::wdAutoFitContent
)

$vmTable.Style = "Medium Shading 1 - Accent 1"
$vmTable.Cell(1,1).Range.Text = "Name"
$vmTable.Cell(1,2).Range.Text = "Computer Name"
$vmTable.Cell(1,3).Range.Text = "Operating System"
$vmTable.Cell(1,4).Range.Text = "Disk Type"
$vmTable.Cell(1,5).Range.Text = "VM Size"
$vmTable.Cell(1,6).Range.Text = "VM State"
$vmTable.Cell(1,7).Range.Text = "Resource Group Name"
$vmTable.Cell(1,8).Range.Text = "Location"
$vmTable.Cell(1,9).Range.Text = "Network Interface"

## Values
$i=0
Foreach ($vm in $vms) 
{
    $vmName = $vm.NetworkInterfaceIDs
    $parts = ($vm.NetworkProfile.NetworkInterfaces.id).split("/")
    $nicLabel = $parts[8]
    $diskSKU = (Get-AzDisk -DiskName $VM.StorageProfile.OsDisk.Name).Sku.name
    $vmTable.cell(($i+2),1).range.Bold = 0
    $vmTable.cell(($i+2),1).range.text = $vm.Name
    $vmTable.cell(($i+2),2).range.Bold = 0
    $vmTable.cell(($i+2),2).range.text = $vm.OSProfile.ComputerName
    $vmTable.cell(($i+2),3).range.Bold = 0
    $vmTable.cell(($i+2),3).range.text = ($vm.StorageProfile.OsDisk.OsType).ToString()
    $vmTable.cell(($i+2),4).range.Bold = 0
    $vmTable.cell(($i+2),4).range.text = $diskSKU
    $vmTable.cell(($i+2),5).range.Bold = 0
    $vmTable.cell(($i+2),5).range.text = $vm.HardwareProfile.VmSize
    $vmTable.cell(($i+2),6).range.Bold = 0
    $vmTable.cell(($i+2),6).range.text = $vm.PowerState
    $vmTable.cell(($i+2),7).range.Bold = 0
    $vmTable.cell(($i+2),7).range.text = $vm.ResourceGroupName
    $vmTable.cell(($i+2),8).range.Bold = 0
    $vmTable.cell(($i+2),8).range.text = $vm.Location
    $vmTable.cell(($i+2),9).range.Bold = 0
    $vmTable.cell(($i+2),9).range.text = $nicLabel
    $i++
}

$Word.Selection.Start= $Document.Content.End
$Selection.TypeParagraph()