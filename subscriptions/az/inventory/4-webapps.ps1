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