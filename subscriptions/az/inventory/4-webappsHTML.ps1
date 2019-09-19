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
$filename = "c:\temp\apps-sample-"+($subscriptions[$subscriptionChoice].Name)+".html"
Add-Content -Path $filename -Value `
('<h1>Azure Documentation - '+($subscriptions[$subscriptionChoice].Name)+'</h1>')

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