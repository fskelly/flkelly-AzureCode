$ErrorActionPreference = "silentlyContinue"

# Connect to Azure and get all VMs in a resource group
##Connect-AzAccount
# Select the Subscription to run the command against
$sub = Select-AzSubscription -SubscriptionId "949ef534-07f5-4138-8b79-aae16a71310c"

# Creating the Word Object, set Word to visual and add document
$Word = New-Object -ComObject Word.Application
$Word.Visible = $True
$Document = $Word.Documents.Add()
$Selection = $Word.Selection

## Add some text to start with
$Selection.Style = 'Title'
$Selection.TypeText("Azure Documentation - "  + $sub.Subscription.Name)
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
$VMs = Get-AzVM -Status

## Add a table for VMs
$VMTable = $Selection.Tables.add($Word.Selection.Range, $VMs.Count + 2, 7,
[Microsoft.Office.Interop.Word.WdDefaultTableBehavior]::wdWord9TableBehavior,
[Microsoft.Office.Interop.Word.WdAutoFitBehavior]::wdAutoFitContent
)

$VMTable.Style = "Medium Shading 1 - Accent 1"
$VMTable.Cell(1,1).Range.Text = "Name"
$VMTable.Cell(1,2).Range.Text = "Computer Name"
$VMTable.Cell(1,3).Range.Text = "Operating System"
$VMTable.Cell(1,4).Range.Text = "VM Size"
$VMTable.Cell(1,5).Range.Text = "VM State"
$VMTable.Cell(1,6).Range.Text = "Resource Group Name"
$VMTable.Cell(1,7).Range.Text = "Network Interface"

## Values
$i=0
Foreach ($VM in $VMs) 
{
    $VMName = $VM.NetworkInterfaceIDs
    $Parts = ($VM.NetworkProfile.NetworkInterfaces.id).split("/")
    ##$Parts = $VMName.Split("/")
    $NICLabel = $Parts[8]
    $VMTable.cell(($i+2),1).range.Bold = 0
    $VMTable.cell(($i+2),1).range.text = $VM.Name
    $VMTable.cell(($i+2),2).range.Bold = 0
    $VMTable.cell(($i+2),2).range.text = $VM.OSProfile.ComputerName
    $VMTable.cell(($i+2),3).range.Bold = 0
    $VMTable.cell(($i+2),3).range.text = ($VM.StorageProfile.OsDisk.OsType).ToString()
    $VMTable.cell(($i+2),4).range.Bold = 0
    $VMTable.cell(($i+2),4).range.text = $VM.HardwareProfile.VmSize
    $VMTable.cell(($i+2),5).range.Bold = 0
    $VMTable.cell(($i+2),5).range.text = $VM.PowerState
    $VMTable.cell(($i+2),6).range.Bold = 0
    $VMTable.cell(($i+2),6).range.text = $VM.ResourceGroupName
    $VMTable.cell(($i+2),7).range.Bold = 0
    $VMTable.cell(($i+2),7).range.text = $NICLabel
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

$NICs = Get-AzNetworkInterface

$NICTable = $Selection.Tables.add($Word.Selection.Range, $NICs.Count + 2, 7,
[Microsoft.Office.Interop.Word.WdDefaultTableBehavior]::wdWord9TableBehavior,
[Microsoft.Office.Interop.Word.WdAutoFitBehavior]::wdAutoFitContent
)

$NICTable.Style = "Medium Shading 1 - Accent 1"
$NICTable.Cell(1,1).Range.Text = "Virtual Machine"
$NICTable.Cell(1,2).Range.Text = "Network Card Name"
$NICTable.Cell(1,3).Range.Text = "Resource Group Name"
$NICTable.Cell(1,4).Range.Text = "VNET"
$NICTable.Cell(1,5).Range.Text = "Subnet"
$NICTable.Cell(1,6).Range.Text = "Private IP Address"
$NICTable.Cell(1,7).Range.Text = "Private IP Allocation Method"



## Write NICs to NIC table 
$i=0
Foreach ($NIC in $NICs) 
{

    ## Get connected VM, if there is one connected to the network interface
    If (!$NIC.VirtualMachine.id) 
    { 
        $VMLabel = " "
    }
    Else
    {
        $VMName = $NIC.VirtualMachine.id
        $Parts = $VMName.Split("/")
        $VMLabel = $PArts[8]
    }

## GET VNET and SUBNET

    $NETCONF = $NIC.IPconfigurations.subnet.id
    $Parts = $NETCONF.Split("/")
    $VNETNAME = $Parts[8]
    $SUBNETNAME = $Parts[10]

    $NICTable.cell(($i+2),1).range.Bold = 0
    $NICTable.cell(($i+2),1).range.text = $VMLabel
    $NICTable.cell(($i+2),2).range.Bold = 0
    $NICTable.cell(($i+2),2).range.text = $NIC.Name
    $NICTable.cell(($i+2),3).range.Bold = 0
    $NICTable.cell(($i+2),3).range.text = $NIC.ResourceGroupName
    $NICTable.cell(($i+2),4).range.Bold = 0
    $NICTable.cell(($i+2),4).range.text = $VNETNAME 
    $NICTable.cell(($i+2),5).range.Bold = 0
    $NICTable.cell(($i+2),5).range.text = $SUBNETNAME
    $NICTable.cell(($i+2),6).range.Bold = 0   
    $NICTable.cell(($i+2),6).range.text = $NIC.IPconfigurations.PrivateIpAddress
    $NICTable.cell(($i+2),7).range.Bold = 0
    $NICTable.cell(($i+2),7).range.text = $NIC.IPconfigurations.PrivateIpAllocationMethod
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

$NSGs = Get-AzNetworkSecurityGroup

$NSGTable = $Selection.Tables.add($Word.Selection.Range, $NSGs.Count + 2, 4,
[Microsoft.Office.Interop.Word.WdDefaultTableBehavior]::wdWord9TableBehavior,
[Microsoft.Office.Interop.Word.WdAutoFitBehavior]::wdAutoFitContent
)

$NSGTable.Style = "Medium Shading 1 - Accent 1"
$NSGTable.Cell(1,1).Range.Text = "NSG Name"
$NSGTable.Cell(1,2).Range.Text = "Resource Group Name"
$NSGTable.Cell(1,3).Range.Text = "Network Interfaces"
$NSGTable.Cell(1,4).Range.Text = "Subnets"

## Write NICs to NIC table 
$i=0
Foreach ($NSG in $NSGs) 
{

    ## Get connected NIC, if there is one connected 
    If (!$NSG.NetworkInterfaces.Id) 
    { 
        $NICLabel = " "
    }
    Else
    {
        $SubnetName = $NSG.NetworkInterfaces.Id
        $Parts = ($NSG.NetworkInterfaces.Id).split("/")
        $NICLabel = $Parts[8]
    }



## Get connected SUBNET, if there is one connected 
If (!$NSG.Subnets.Id) 
    { 
        $SubnetLabel = " "
    }
Else
    {
        $SUBNETName = $NSG.Subnets.Id
        $Parts = $SUBNETName.Split("/")
        $SUBNETLabel = $Parts[10]
    }

    $NSGTable.cell(($i+2),1).range.Bold = 0
    $NSGTable.cell(($i+2),1).range.text = $NSG.Name
    $NSGTable.cell(($i+2),2).range.Bold = 0
    $NSGTable.cell(($i+2),2).range.text = $NSG.ResourceGroupName
    $NSGTable.cell(($i+2),3).range.Bold = 0
    $NSGTable.cell(($i+2),3).range.text = $NICLabel
    $NSGTable.cell(($i+2),4).range.Bold = 0
    $NSGTable.cell(($i+2),4).range.text = $SUBNETLabel
    $i++
}

$Word.Selection.Start= $Document.Content.End
$Selection.TypeParagraph()

########
######## Create a table for each NSG
########

### Get all NSGs
$NSGs = Get-AzNetworkSecurityGroup

ForEach ($NSG in $NSGs) 
{

    ## Add Heading for each NSG
    $Selection.Style = 'Heading 2'
    $Selection.TypeText($NSG.Name)
    $Selection.TypeParagraph()

    
    ### Add a table for each NSG, the NSg has custom rules
    $NSGRuleTable = $Selection.Tables.add($Word.Selection.Range, $NSG.SecurityRules.Count + 2, 9,
    [Microsoft.Office.Interop.Word.WdDefaultTableBehavior]::wdWord9TableBehavior,
    [Microsoft.Office.Interop.Word.WdAutoFitBehavior]::wdAutoFitContent
    )

    $NSGRuleTable.Style = "Medium Shading 1 - Accent 1"
    $NSGRuleTable.Cell(1,1).Range.Text = "Rule Name"
    $NSGRuleTable.Cell(1,2).Range.Text = "Protocol"
    $NSGRuleTable.Cell(1,3).Range.Text = "Source Port Range"
    $NSGRuleTable.Cell(1,4).Range.Text = "Destination Port Range"
    $NSGRuleTable.Cell(1,5).Range.Text = "Source Address Prefix"
    $NSGRuleTable.Cell(1,6).Range.Text = "Destination Address Prefix"
    $NSGRuleTable.Cell(1,7).Range.Text = "Access"
    $NSGRuleTable.Cell(1,8).Range.Text = "Priority"
    $NSGRuleTable.Cell(1,9).Range.Text = "Direction"


    ### Get all custom Security Rules in the NSG
    $NSGRules = Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $NSG
    $i = 0

    ForEach ($NSGRule in $NSGRules) 
    {
        $NSGRuleTable.cell(($i+2),1).range.Bold = 0
        $NSGRuleTable.cell(($i+2),1).range.text = $NSGRule.Name

        $NSGRuleTable.cell(($i+2),2).range.Bold = 0
        $NSGRuleTable.cell(($i+2),2).range.text = $NSGRule.Protocol

        $NSGRuleTable.cell(($i+2),3).range.Bold = 0
        $NSGRuleTable.cell(($i+2),3).range.text = $NSGRule.SourcePortRange

        $NSGRuleTable.cell(($i+2),4).range.Bold = 0
        $NSGRuleTable.cell(($i+2),4).range.text = $NSGRule.DestinationPortRange

        $NSGRuleTable.cell(($i+2),5).range.Bold = 0
        $NSGRuleTable.cell(($i+2),5).range.text = $NSGRule.SourceAddressPrefix

        $NSGRuleTable.cell(($i+2),6).range.Bold = 0
        $NSGRuleTable.cell(($i+2),6).range.text = $NSGRule.DestinationAddressPrefix

        $NSGRuleTable.cell(($i+2),7).range.Bold = 0
        $NSGRuleTable.cell(($i+2),7).range.text = $NSGRule.Access

        $NSGRuleTable.cell(($i+2),8).range.Bold = 0
        $NSGRuleTable.cell(($i+2),8).range.text = [string]$NSGRule.Priority

        $NSGRuleTable.cell(($i+2),9).range.Bold = 0
        $NSGRuleTable.cell(($i+2),9).range.text = $NSGRule.Direction

        $NSGRule.Name
        $NSGRule.DestinationPortRange

        $i++
    }

    ### Get all default Security Rules in the NSG
<#     $NSGRules = Get-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $NSG -DefaultRules

    ForEach ($NSGRule in $NSGRules) 
    {
            $NSGRuleTable.cell(($i+2),1).range.Bold = 0
            $NSGRuleTable.cell(($i+2),1).range.text = $NSGRule.Name

            $NSGRuleTable.cell(($i+2),2).range.Bold = 0
            $NSGRuleTable.cell(($i+2),2).range.text = $NSGRule.Protocol

            $NSGRuleTable.cell(($i+2),3).range.Bold = 0
            $NSGRuleTable.cell(($i+2),3).range.text = $NSGRule.SourcePortRange

            $NSGRuleTable.cell(($i+2),4).range.Bold = 0
            $NSGRuleTable.cell(($i+2),4).range.text = $NSGRule.DestinationPortRange

            $NSGRuleTable.cell(($i+2),5).range.Bold = 0
            $NSGRuleTable.cell(($i+2),5).range.text = $NSGRule.SourceAddressPrefix

            $NSGRuleTable.cell(($i+2),6).range.Bold = 0
            $NSGRuleTable.cell(($i+2),6).range.text = $NSGRule.DestinationAddressPrefix

            $NSGRuleTable.cell(($i+2),7).range.Bold = 0
            $NSGRuleTable.cell(($i+2),7).range.text = $NSGRule.Access

            $NSGRuleTable.cell(($i+2),8).range.Bold = 0
            $NSGRuleTable.cell(($i+2),8).range.text = [string]$NSGRule.Priority

            $NSGRuleTable.cell(($i+2),9).range.Bold = 0
            $NSGRuleTable.cell(($i+2),9).range.text = $NSGRule.Direction

            $i++
            ##$NSGRule.Name
            ##$NSGRule.DestinationPortRange
            ##$NSGRule | GM
            ##$NSGRule

    } #>

    ### Close the NSG table
    $Word.Selection.Start= $Document.Content.End
    $Selection.TypeParagraph()

}

### Update the TOC now when all data has been written to the document 
$toc.Update()

# Save the document
$Report = 'C:\Temp\Azure_document_' +$sub.Subscription.name+ '.doc'
$Document.SaveAs([ref]$Report,[ref]$SaveFormat::wdFormatDocument)
$word.Quit()

# Free up memory
$null = [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$word)
[gc]::Collect()
[gc]::WaitForPendingFinalizers()
Remove-Variable word 
