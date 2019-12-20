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

## Original Credit - https://4sysops.com/archives/creating-an-azure-front-door-using-powershell/
## Install-Module -Name Az.FrontDoor -Force

## Starting Loop
$i = 1

## update locations to meet your needs, web app will be deployed to each region below
$locations = "East US","West Europe","South Africa North"
foreach ($location in $locations)
{
    switch ($location) 
    {
        "West Europe"  {$prefix = "weu"; break}
        "East US"   {$prefix = "eus"; break}
        "South Africa North" {$prefix = "zan"; break}
        default {$prefix = "zan"; break}
    }

    # Replace the following URL with a public GitHub repo URL
    $gitrepo="https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git"

    ## Please update variables as needed
    $webappname="mywebapp1-$prefix-$(Get-Random)"
    $resourceGroupName = "webapp-$prefix-asp1"

    # Create a resource group.
    New-AzResourceGroup -Name $resourceGroupName -Location $location

    # Create an App Service plan in Free tier.
    New-AzAppServicePlan -Name $webappname -Location $location -ResourceGroupName $resourceGroupName -Tier Free

    # Create a web app.
    New-AzWebApp -Name $webappname -Location $location -AppServicePlan $webappname -ResourceGroupName $resourceGroupName

    # Configure GitHub deployment from your GitHub repo and deploy once.
    $PropertiesObject = @{
        repoUrl = "$gitrepo";
        branch = "master";
        isManualIntegration = "true";
    }
    Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName $resourceGroupName -ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName $webappname/web -ApiVersion 2015-08-01 -Force

    ## Creating variable for web site URLs
    $webAppUrl = (Get-AzWebApp -Name $webappname).DefaultHostName
    New-Variable -Name "url$i" -Value $webAppUrl
    get-Variable -Name "url$i" -ValueOnly

    $i++
}
write-host "URLs: "
(Get-Variable -Name url*)
