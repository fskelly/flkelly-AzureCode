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
    $defaultNSGRuleConfig = ((Get-AzNetworkSecurityGroup -Name $nsg.Name -ResourceGroupName $nsg.ResourceGroupName).DefaultSecurityRules) | Select-Object Name,Description,Priority,Protocol,Access,Direction,@{Name=’SourceAddressPrefix’;Expression={[string]::join(“,”, ($_.SourceAddressPrefix))}},@{Name=’SourcePortRange’;Expression={[string]::join(“,”, ($_.SourcePortRange))}},@{Name=’DestinationAddressPrefix’;Expression={[string]::join(“,”, ($_.DestinationAddressPrefix))}},@{Name=’DestinationPortRange’;Expression={[string]::join(“,”, ($_.DestinationPortRange))}}
    $customNSGRuleConfig = (Get-AzNetworkSecurityGroup -Name $nsg.Name -ResourceGroupName $nsg.ResourceGroupName).SecurityRules  | Select-Object Name,Description,Priority,Protocol,Access,Direction,@{Name=’SourceAddressPrefix’;Expression={[string]::join(“,”, ($_.SourceAddressPrefix))}},@{Name=’SourcePortRange’;Expression={[string]::join(“,”, ($_.SourcePortRange))}},@{Name=’DestinationAddressPrefix’;Expression={[string]::join(“,”, ($_.DestinationAddressPrefix))}},@{Name=’DestinationPortRange’;Expression={[string]::join(“,”, ($_.DestinationPortRange))}}
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

