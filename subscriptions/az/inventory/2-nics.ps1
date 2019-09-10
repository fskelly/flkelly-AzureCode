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
#$sub = Select-AzSubscription -SubscriptionId "949ef534-07f5-4138-8b79-aae16a71310c"

# Creating the Word Object, set Word to visual and add document
$Word = New-Object -ComObject Word.Application
$Word.Visible = $True
$Document = $Word.Documents.Add()
$Selection = $Word.Selection

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
    $nicTable.cell(($i+2),7).range.text = ($nic.IPconfigurations | Where-Object {$_.Primary -eq "True"}).PrivateIpAllocationMethod
    $nicTable.cell(($i+2),8).range.Bold = 0   
    $nicTable.cell(($i+2),8).range.text = $publicIP
    $nicTable.cell(($i+2),9).range.Bold = 0   
    $nicTable.cell(($i+2),9).range.text = $publicIPAllocationMethod
    $i++
}

$Word.Selection.Start= $Document.Content.End
$Selection.TypeParagraph()