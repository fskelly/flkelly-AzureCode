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
$filename = "c:\temp\nsgs-sample-"+($subscriptions[$subscriptionChoice].Name)+".html"

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
    #$allNSGRuleConfig = $defaultNSGRuleConfig + $customNSGRuleConfig
    #$allNSGRuleConfig.Count
    $totalNSGRuleCount = $customNSGRuleConfig.Count + $defaultNSGRuleConfig.Count
    ##$defaultNSGRuleConfig
    #$customNSGRuleConfig

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

