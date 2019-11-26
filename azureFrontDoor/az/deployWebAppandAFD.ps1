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
$appCount = 2


## please add or modify as needed
switch ($appCount)
{
    "1" { $locations = "South Africa North" }
    "2" { $locations = "West Europe","South Africa North" }
    "3" { $locations = "East US","West Europe","South Africa North"}
    default { $locations = "West Europe","South Africa North" }
}

foreach ($location in $locations)
{
    switch ($location) 
    {
        "West Europe"  {$identifier = "weu"; break}
        "East US"   {$identifier = "eus"; break}
        "South Africa North" {$identifier = "zan"; break}
        default {$identifier = "zan"; break}
    }

    # Replace the following URL with a public GitHub repo URL
    $gitrepo="https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git"

    ## Please update variables as needed
    $webappname="afd-mywebapp001-$identifier-$(Get-Random)"
    $resourceGroupName = "afd-$identifier-asp001"

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

## Getting number of URLs
$urlCount = (Get-Variable -Name url*).count
$urlCount


## Update variables as needed
$afdResourceGroupName = ""
$adfLocation = ""
$routingRuleName = "routingRule1"
$afdName = ""
$FrontendEndpointName = "frontendEndpoint1"
$backendpoolname = "backendPool1"
$hostName="xxx.azurefd.net"


New-AzResourceGroup -Name $afdResourceGroupName -Location $adfLocation

### 1. Creating a new Azure Front Door health probe setting object ####

$HealthProbeSettingObject1 = New-AzFrontDoorHealthProbeSettingObject -Name "HealthProbeSetting1"
$HealthProbeSettingObject1

### 2. Creating a New Azure Front Door load-balancing setting object ####

$LoadBalancingSettingObject1 = New-AzFrontDoorLoadBalancingSettingObject -Name "Loadbalancingsetting1"
$LoadBalancingSettingObject1

### 3. Creating a new Azure Front Door front-end endpoint object ####

$FrontendEndpointObject1 = New-AzFrontDoorFrontendEndpointObject -Name "frontendEndpointObject1" -HostName $hostName
$FrontendEndpointObject1


### 4. Creating a new Azure Front Door backend object based on original count ####

switch ($urlCount)
{
    "1" 
    { 
        $backEndObject1 = New-AzFrontDoorBackendObject -Address $url1
        $backEndObject1

        ### 5. Creating a new Azure Front Door backend pool object #####
        $BackendPoolObject1 = New-AzFrontDoorBackendPoolObject -Name $backendpoolname `
        -FrontDoorName $afdName `
        -ResourceGroupName $afdResourceGroupName `
        -Backend $backEndObject1 `
        -HealthProbeSettingsName "HealthProbeSetting1" `
        -LoadBalancingSettingsName "Loadbalancingsetting1"
        $BackendPoolObject1
    }
    "2" 
    { 
        $backEndObject1 = New-AzFrontDoorBackendObject -Address $url1
        $backEndObject2 = New-AzFrontDoorBackendObject -Address $url2
        $backEndObject1
        $backEndObject2

        ### 5. Creating a new Azure Front Door backend pool object #####
        $BackendPoolObject1 = New-AzFrontDoorBackendPoolObject -Name $backendpoolname `
        -FrontDoorName $afdName `
        -ResourceGroupName $afdResourceGroupName `
        -Backend $backEndObject1,$backEndObject2 `
        -HealthProbeSettingsName "HealthProbeSetting1" `
        -LoadBalancingSettingsName "Loadbalancingsetting1"
        $BackendPoolObject1
    }
    "3" 
    { 
        $backEndObject1 = New-AzFrontDoorBackendObject -Address $url1
        $backEndObject2 = New-AzFrontDoorBackendObject -Address $url2
        $backEndObject3 = New-AzFrontDoorBackendObject -Address $url3
        $backEndObject1
        $backEndObject2
        $backEndObject3

        ### 5. Creating a new Azure Front Door backend pool object #####
        $BackendPoolObject1 = New-AzFrontDoorBackendPoolObject -Name $backendpoolname `
        -FrontDoorName $afdName `
        -ResourceGroupName $afdResourceGroupName `
        -Backend $backEndObject1,$backEndObject2,$backEndObject3 `
        -HealthProbeSettingsName "HealthProbeSetting1" `
        -LoadBalancingSettingsName "Loadbalancingsetting1"
        $BackendPoolObject1
    }
    default 
    { 
        $backEndObject1 = New-AzFrontDoorBackendObject -Address $url1
        $backEndObject2 = New-AzFrontDoorBackendObject -Address $url2
        $backEndObject1
        $backEndObject2

        ### 5. Creating a new Azure Front Door backend pool object #####
        $BackendPoolObject1 = New-AzFrontDoorBackendPoolObject -Name $backendpoolname `
        -FrontDoorName $afdName `
        -ResourceGroupName $afdResourceGroupName `
        -Backend $backEndObject1,$backEndObject2 `
        -HealthProbeSettingsName "HealthProbeSetting1" `
        -LoadBalancingSettingsName "Loadbalancingsetting1"
        $BackendPoolObject1
    }
}


### 6. Creating a new Azure Front Door routing object ####

$RoutingRuleObject1 = New-AzFrontDoorRoutingRuleObject -Name $routingRuleName `
-FrontDoorName $afdName `
-ResourceGroupName $afdResourceGroupName `
-FrontendEndpointName "frontendEndpointObject1" `
-BackendPoolName "backendPool1"
$RoutingRuleObject1

### 7. Creating a new Azure Front Door ####

$AzureFrontDoor = New-AzFrontDoor -Name $afdName `
-ResourceGroupName $afdResourceGroupName `
-RoutingRule $RoutingRuleObject1 `
-BackendPool $BackendPoolObject1 `
-FrontendEndpoint $FrontendEndpointObject1 `
-LoadBalancingSetting $LoadBalancingSettingObject1 `
-HealthProbeSetting $HealthProbeSettingObject1
$AzureFrontDoor