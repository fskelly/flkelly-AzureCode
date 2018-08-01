Function Connect-to-ARM
{
  Login-AzureRmAccount
  $subscriptions = Get-AzureRMSubscription | Sort-Object SubscriptionName | Select-Object Name,SubscriptionId
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
  Set-AzureRmContext -SubscriptionId $subscriptions[$subscriptionChoice].SubscriptionId
}


$Now = (get-date)
$date = ( Get-Date ).ToString('dd.MM.yyyy-HH.mm.ss')

Connect-to-ARM

$sub = Get-AzureRmSubscription
$subscriptionName = $sub.SubscriptionName

$VMs = Get-AzureRmVM
$VMAllInfo = @()

Foreach ($vm in $VMs)
{
  $VMInfo = New-Object system.object
  $ipInterface = (Get-AzureRmNetworkInterface) | Where-Object {$_.id -eq  ($vm.NetworkProfile.NetworkInterfaces).id}
  $VMName = $vm.name
  $prvint =  $ipInterface.IpConfigurations
  $prv = $prvint.PrivateIpAddress
  $alloc = $prvint.PrivateIpAllocationMethod
  $pubint = (Get-AzureRmPublicIpAddress | Where-Object {$_.id -eq $ipInterface.IpConfigurations.PublicIPAddress.id})
  $pubip = $pubint.IpAddress
  $puballoc = $pubint.PublicIpAllocationMethod
  $endPointInfo = @()
  $nsg = (Get-AzureRmNetworkSecurityGroup | Where-Object {$_.NetworkInterfaces.id -eq $vm.NetworkInterfaceIDs})
  foreach ($rule in $nsg.SecurityRules)
  {
    $info = @()
    Write-host "Processing" $rule.Name
    [string]$nsgName = $rule.Name
    [string]$nsgProtocol = $rule.protocol
    [string]$nsgPort = $rule.destinationPortRange
    [string]$nsgAccess = $rule.Access
    [string]$nsgDirection = $rule.direction
    [string]$info = "$nsgName ($nsgProtocol [$nsgPort]) - $nsgAccess [$nsgDirection]"
    $info
    $endpointInfo += [string]::Join(" ; ",$info)
  }
  $endpointInfo = [string]::Join(",",$endpointInfo)
  $VMInfo | Add-Member NoteProperty -name VMname -value $VMName
  $VMInfo | Add-Member NoteProperty -name InternalIP -value $prv
  $VMInfo | Add-Member NoteProperty -name InternalIPAllocation -value $alloc
  $VMInfo | Add-Member NoteProperty -name PublicIP -value $pubip
  $VMInfo | Add-Member NoteProperty -name PublicIPAllocation -value $puballoc
  $VMInfo | Add-Member NoteProperty -name PublicIPRuleInfo -Value $endpointInfo
  $VMAllInfo += $VMInfo
}

$Pre = "Azure VM Info"
$Post = "Report executed @ $Now for $subscriptionName"

$Header = @"
<style type="text/css">
              table.table-style-three {
                           font-family: verdana, arial, sans-serif;
                           font-size: 11px;
                           color: #333333;
                           border-width: 1px;
                           border-color: #3A3A3A;
                           border-collapse: collapse;
              }
              table.table-style-three th {
                           border-width: 1px;
                           padding: 8px;
                           border-style: solid;
                           border-color: #FFA6A6;
                           background-color: #D56A6A;
                           color: #ffffff;
              }
              table.table-style-three tr:hover td {
                           cursor: pointer;
              }
              table.table-style-three tr:nth-child(even) td{
                           background-color: #F7CFCF;
              }
              table.table-style-three td {
                           border-width: 1px;
                           padding: 8px;
                           border-style: solid;
                           border-color: #FFA6A6;
                           background-color: #ffffff;
              }
</style>
<title>
Azure Public Endpoints
</title>
"@

$content = $VMAllInfo | ConvertTo-HTML -Head $Header -PreContent $Pre -PostContent $Post #| out-file $workItemfileName
$csscontent = $content -replace "<table>","<table class=""table-style-three"">"
$csscontent | out-file $env:USERPROFILE\Desktop\$subscriptionName-$date.html
Write-Host "You can find the file here: " -NoNewline
Write-host "$env:USERPROFILE\Desktop\$subscriptionName-$date.html"
