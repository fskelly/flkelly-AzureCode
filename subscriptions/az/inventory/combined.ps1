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


$ErrorActionPreference = "silentlyContinue"

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

########
######## NETWORK INTERFACE
########

$Selection.Style = 'Heading 1'
$Selection.TypeText("Network Interfaces")
$Selection.TypeParagraph()

$nics = Get-AzNetworkInterface

$nicTable = $Selection.Tables.add($Word.Selection.Range, $NICs.Count + 2, 9,
[Microsoft.Office.Interop.Word.WdDefaultTableBehavior]::wdWord9TableBehavior,
[Microsoft.Office.Interop.Word.WdAutoFitBehavior]::wdAutoFitContent
)

$nicTable.Style = "Medium Shading 1 - Accent 1"
$nicTable.Cell(1,1).Range.Text = "Virtual Machine"
$nicTable.Cell(1,2).Range.Text = "Network Card Name"
$nicTable.Cell(1,3).Range.Text = "Resource Group Name"
$nicTable.Cell(1,4).Range.Text = "VNET"
$nicTable.Cell(1,5).Range.Text = "Subnet"
$nicTable.Cell(1,6).Range.Text = "Private IP Address"
$nicTable.Cell(1,7).Range.Text = "Private IP Allocation Method"
$nicTable.Cell(1,8).Range.Text = "Public IP Address"
$nicTable.Cell(1,9).Range.Text = "Public IP Allocation Method"



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
    $publicIP = (Get-AzPublicIpAddress -Name ($nic.IpConfigurations.PublicIpAddress.id).Split('/')[8]).IpAddress
    if ($publicIP -eq 'Not Assigned')
    {
        $publicIP = "N/A"
        $publicIPAllocationMethod = "N/A"
    }
    else 
    {
        $publicIPAllocationMethod = (Get-AzPublicIpAddress -Name ($nic.IpConfigurations.PublicIpAddress.id).Split('/')[8]).PublicIpAllocationMethod
    }

## GET VNET and SUBNET

    $networkConfig = $nic.IPconfigurations.subnet.id
    $parts = $networkConfig.Split("/")
    $vnetName = $parts[8]
    $subnetName = $parts[10]

    $nicTable.cell(($i+2),1).range.Bold = 0
    $nicTable.cell(($i+2),1).range.text = $vmLabel
    $nicTable.cell(($i+2),2).range.Bold = 0
    $nicTable.cell(($i+2),2).range.text = $nic.Name
    $nicTable.cell(($i+2),3).range.Bold = 0
    $nicTable.cell(($i+2),3).range.text = $nic.ResourceGroupName
    $nicTable.cell(($i+2),4).range.Bold = 0
    $nicTable.cell(($i+2),4).range.text = $vnetName 
    $nicTable.cell(($i+2),5).range.Bold = 0
    $nicTable.cell(($i+2),5).range.text = $subnetName
    $nicTable.cell(($i+2),6).range.Bold = 0   
    $nicTable.cell(($i+2),6).range.text = ($nic.IPconfigurations | Where-Object {$_.Primary -eq "True"}).PrivateIpAddress
    $nicTable.cell(($i+2),7).range.Bold = 0
    $nicTable.cell(($i+2),7).range.text = $nic.IPconfigurations.PrivateIpAllocationMethod
    $nicTable.cell(($i+2),8).range.Bold = 0   
    $nicTable.cell(($i+2),8).range.text = $publicIP
    $nicTable.cell(($i+2),9).range.Bold = 0   
    $nicTable.cell(($i+2),9).range.text = $publicIPAllocationMethod
    $i++
}

$Word.Selection.Start= $Document.Content.End
$Selection.TypeParagraph()

########
######## Create a table for NSG
########

## Add some text
$Selection.Style = 'Heading 1'
$Selection.TypeText("Network Security Groups")
$Selection.TypeParagraph()

########
######## Create a table for each NSG
########

### Get all NSGs
$nsgs = Get-AzNetworkSecurityGroup

ForEach ($nsg in $nsgs) 
{

    ## Add Heading for each NSG
    $Selection.Style = 'Heading 2'
    $Selection.TypeText($nsg.Name)
    $Selection.TypeParagraph()

    ##get nsg rulesets
    $defaultNSGRuleConfig = ((Get-AzNetworkSecurityGroup -Name $nsg.Name -ResourceGroupName $nsg.ResourceGroupName).DefaultSecurityRules) | Select-Object Name,Description,Priority,Protocol,Access,Direction,@{Name='SourceAddressPrefix';Expression={[string]::join(",", ($_.SourceAddressPrefix))}},@{Name='SourcePortRange';Expression={[string]::join(",", ($_.SourcePortRange))}},@{Name='DestinationAddressPrefix';Expression={[string]::join(",", ($_.DestinationAddressPrefix))}},@{Name='DestinationPortRange';Expression={[string]::join(",", ($_.DestinationPortRange))}}
    $customNSGRuleConfig = (Get-AzNetworkSecurityGroup -Name $nsg.Name -ResourceGroupName $nsg.ResourceGroupName).SecurityRules  | Select-Object Name,Description,Priority,Protocol,Access,Direction,@{Name='SourceAddressPrefix';Expression={[string]::join(",", ($_.SourceAddressPrefix))}},@{Name='SourcePortRange';Expression={[string]::join(",", ($_.SourcePortRange))}},@{Name='DestinationAddressPrefix';Expression={[string]::join(",", ($_.DestinationAddressPrefix))}},@{Name='DestinationPortRange';Expression={[string]::join(",", ($_.DestinationPortRange))}}
    #$allNSGRuleConfig = $defaultNSGRuleConfig + $customNSGRuleConfig
    #$allNSGRuleConfig.Count
    $totalNSGRuleCount = $customNSGRuleConfig.Count + $defaultNSGRuleConfig.Count
    ##$defaultNSGRuleConfig
    #$customNSGRuleConfig

    ### Add a table for each NSG, the NSg has custom rules
    $NSGRuleTable = $Selection.Tables.add($Word.Selection.Range, $totalNSGRuleCount + 2, 9,
    [Microsoft.Office.Interop.Word.WdDefaultTableBehavior]::wdWord9TableBehavior,
    [Microsoft.Office.Interop.Word.WdAutoFitBehavior]::wdAutoFitContent
    )

    $i = 0 

    $nsgRuleTable.Style = "Medium Shading 1 - Accent 1"
    $nsgRuleTable.Cell(1,1).Range.Text = "Rule Name"
    $nsgRuleTable.Cell(1,2).Range.Text = "Protocol"
    $nsgRuleTable.Cell(1,3).Range.Text = "Source Port Range"
    $nsgRuleTable.Cell(1,4).Range.Text = "Destination Port Range"
    $nsgRuleTable.Cell(1,5).Range.Text = "Source Address Prefix"
    $nsgRuleTable.Cell(1,6).Range.Text = "Destination Address Prefix"
    $nsgRuleTable.Cell(1,7).Range.Text = "Access"
    $nsgRuleTable.Cell(1,8).Range.Text = "Priority"
    $nsgRuleTable.Cell(1,9).Range.Text = "Direction"

    foreach ($defaultRule in $defaultNSGRuleConfig)
    {
        $nsgRuleTable.cell(($i+2),1).range.Bold = 0
        $nsgRuleTable.cell(($i+2),1).range.text = $defaultRule.Name

        $nsgRuleTable.cell(($i+2),2).range.Bold = 0
        $nsgRuleTable.cell(($i+2),2).range.text = $defaultRule.Protocol

        $nsgRuleTable.cell(($i+2),3).range.Bold = 0
        $nsgRuleTable.cell(($i+2),3).range.text = $defaultRule.SourcePortRange

        $nsgRuleTable.cell(($i+2),4).range.Bold = 0
        $nsgRuleTable.cell(($i+2),4).range.text = $defaultRule.DestinationPortRange

        $nsgRuleTable.cell(($i+2),5).range.Bold = 0
        $nsgRuleTable.cell(($i+2),5).range.text = $defaultRule.SourceAddressPrefix

        $nsgRuleTable.cell(($i+2),6).range.Bold = 0
        $nsgRuleTable.cell(($i+2),6).range.text = $defaultRule.DestinationAddressPrefix

        $nsgRuleTable.cell(($i+2),7).range.Bold = 0
        $nsgRuleTable.cell(($i+2),7).range.text = $defaultRule.Access

        $nsgRuleTable.cell(($i+2),8).range.Bold = 0
        $nsgRuleTable.cell(($i+2),8).range.text = [string]$defaultRule.Priority

        $nsgRuleTable.cell(($i+2),9).range.Bold = 0
        $nsgRuleTable.cell(($i+2),9).range.text = $defaultRule.Direction

        $i++
    }
    foreach ($customRule in $customNSGRuleConfig)
    {
        $DestinationPortRange = $customRule.DestinationPortRange
        $nsgRuleTable.cell(($i+2),1).range.Bold = 0
        $nsgRuleTable.cell(($i+2),1).range.text = $customRule.Name

        $nsgRuleTable.cell(($i+2),2).range.Bold = 0
        $nsgRuleTable.cell(($i+2),2).range.text = $customRule.Protocol

        $nsgRuleTable.cell(($i+2),3).range.Bold = 0
        $nsgRuleTable.cell(($i+2),3).range.text = $customRule.SourcePortRange

        $nsgRuleTable.cell(($i+2),4).range.Bold = 0
        $nsgRuleTable.cell(($i+2),4).range.text = $DestinationPortRange

        $nsgRuleTable.cell(($i+2),5).range.Bold = 0
        $nsgRuleTable.cell(($i+2),5).range.text = $customRule.SourceAddressPrefix

        $nsgRuleTable.cell(($i+2),6).range.Bold = 0
        $nsgRuleTable.cell(($i+2),6).range.text = $customRule.DestinationAddressPrefix

        $nsgRuleTable.cell(($i+2),7).range.Bold = 0
        $nsgRuleTable.cell(($i+2),7).range.text = $customRule.Access

        $nsgRuleTable.cell(($i+2),8).range.Bold = 0
        $nsgRuleTable.cell(($i+2),8).range.text = [string]$customRule.Priority

        $nsgRuleTable.cell(($i+2),9).range.Bold = 0
        $nsgRuleTable.cell(($i+2),9).range.text = $customRule.Direction

        $i++
    }
    ### Close the NSG table
    $Word.Selection.Start= $Document.Content.End
    $Selection.TypeParagraph()
}


###
### Create a table for Web Apps
###

## Add some text
$Selection.Style = 'Heading 1'
$Selection.TypeText("App Service Plans")
$Selection.TypeParagraph()

###########


## Get all App Service Plans from Azure
$appServicePlans = Get-AzAppServicePlan
$appServicePlansCount = $appServicePlans.count

## Add a table for App Service Plans
## building Table header row

## Values
  ### Add a table for each App Service Plan
  $appServiceTable = $Selection.Tables.add($Word.Selection.Range, $appServicePlansCount + 2, 7,
  [Microsoft.Office.Interop.Word.WdDefaultTableBehavior]::wdWord9TableBehavior,
  [Microsoft.Office.Interop.Word.WdAutoFitBehavior]::wdAutoFitContent
  )

  $appServiceTable.Style = "Medium Shading 1 - Accent 1"
  $appServiceTable.Cell(1,1).Range.Text = "Name"
  $appServiceTable.Cell(1,2).Range.Text = "Location"
  $appServiceTable.Cell(1,3).Range.Text = "Resource Group Name"
  $appServiceTable.Cell(1,4).Range.Text = "SKU"
  $appServiceTable.Cell(1,5).Range.Text = "Kind"
  $appServiceTable.Cell(1,6).Range.Text = "Number Of Sites"
  $appServiceTable.Cell(1,7).Range.Text = "Status"

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
  
  $appServiceTable.cell(($i+2),1).range.Bold = 0
  $appServiceTable.cell(($i+2),1).range.text = $aspName

  $appServiceTable.cell(($i+2),2).range.Bold = 0
  $appServiceTable.cell(($i+2),2).range.text = $aspLocation

  $appServiceTable.cell(($i+2),3).range.Bold = 0
  $appServiceTable.cell(($i+2),3).range.text = $aspResourceGroup

  $appServiceTable.cell(($i+2),4).range.Bold = 0
  $appServiceTable.cell(($i+2),4).range.text = $aspSKU

  $appServiceTable.cell(($i+2),5).range.Bold = 0
  $appServiceTable.cell(($i+2),5).range.text = $aspKind

  $appServiceTable.cell(($i+2),6).range.Bold = 0
  $appServiceTable.cell(($i+2),6).range.text = $aspSiteCount.ToString()

  $appServiceTable.cell(($i+2),7).range.Bold = 0
  $appServiceTable.cell(($i+2),7).range.text = $aspStatus.ToString()

  $i++

}

### Close Table
$Word.Selection.Start= $Document.Content.End
$Selection.TypeParagraph()

## Add some text
$Selection.Style = 'Heading 2'
$Selection.TypeText("Apps")
$Selection.TypeParagraph()

Foreach ($asp in $appServicePlans) 
{
  $webApps=Get-AzWebApp -AppServicePlan $asp
  $webAppsCount = $webApps.count

  ##building table for Azure Apps

  $appTable = $Selection.Tables.add($Word.Selection.Range, $webAppsCount + 2, 6,
  [Microsoft.Office.Interop.Word.WdDefaultTableBehavior]::wdWord9TableBehavior,
  [Microsoft.Office.Interop.Word.WdAutoFitBehavior]::wdAutoFitContent
  )

  $appTable.Style = "Medium Shading 1 - Accent 1"
  $appTable.Cell(1,1).Range.Text = "Name"
  $appTable.Cell(1,2).Range.Text = "Service Plan Resource Group Name"
  $appTable.Cell(1,3).Range.Text = "App Resource Group Name"
  $appTable.Cell(1,4).Range.Text = "Kind"
  $appTable.Cell(1,5).Range.Text = "URL"
  $appTable.Cell(1,6).Range.Text = "Status"
  
  
  foreach ($webApp in $webApps)
  {
    $webAppName = $webApp.Name
    $webAppResourceGroup = ($webApp.id).Split("/")[4]
    $webAppKind = $webApp.Kind
    [string]$webAppHostName = $webApp.Hostnames
    $webAppState = $webApp.State
    $aspRG = ($asp.id).Split("/")[4]
    
    $appTable.cell(($i+2),1).range.Bold = 0
    $appTable.cell(($i+2),1).range.text = $webAppName

    $appTable.cell(($i+2),2).range.Bold = 0
    $appTable.cell(($i+2),2).range.text = $aspRG

    $appTable.cell(($i+2),3).range.Bold = 0
    $appTable.cell(($i+2),3).range.text = $webAppResourceGroup

    $appTable.cell(($i+2),4).range.Bold = 0
    $appTable.cell(($i+2),4).range.text = $webAppKind

    $appTable.cell(($i+2),5).range.Bold = 0
    $appTable.cell(($i+2),5).range.text = $webAppHostName

    $appTable.cell(($i+2),6).range.Bold = 0
    $appTable.cell(($i+2),6).range.text = $webAppState

    ### Close Table
    $Word.Selection.Start= $Document.Content.End
    $Selection.TypeParagraph()

  }  
}

### Close Table
$Word.Selection.Start= $Document.Content.End
$Selection.TypeParagraph()

### finalize the document
### Update the TOC now when all data has been written to the document 
$toc.Update()

# Save the document
$Report = 'C:\Temp\Azure_document_' +$subscriptions[$subscriptionChoice].Name+ '.doc'
$Document.SaveAs([ref]$Report,[ref]$SaveFormat::wdFormatDocument)
$word.Quit()

# Free up memory
$null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$word)
[gc]::Collect()
[gc]::WaitForPendingFinalizers()
Remove-Variable word 