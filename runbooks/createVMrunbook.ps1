[CmdletBinding()]
Param
([object]$WebhookData) #this parameter name needs to be called WebHookData otherwise the webhook does not work as expected.
$VerbosePreference = 'continue'

#region Verify if Runbook is started from Webhook.

# If runbook was called from Webhook, WebhookData will not be null.
if ($WebHookData){

    # Collect properties of WebhookData
    $WebhookName     =     $WebHookData.WebhookName
    $WebhookHeaders  =     $WebHookData.RequestHeader
    $WebhookBody     =     $WebHookData.RequestBody

    # Collect individual headers. Input converted from JSON.
    $From = $WebhookHeaders.From
    $Input = (ConvertFrom-Json -InputObject $WebhookBody)
    Write-Verbose "WebhookBody: $Input"
    Write-Output -InputObject ('Runbook started from webhook {0} by {1}.' -f $WebhookName, $From)
}
else
{
   Write-Error -Message 'Runbook was not started from Webhook' -ErrorAction stop
}
#endregion

#region Main

$VMName = $Input.VMName
$Location = $Input.Location
$ResourceGroup = $Input.ResourceGroup

Write-Output -InputObject ('Hello {0} {1}.' -f $VMName, $Location)

$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Login-AzureRmAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint
$AzureContext = Select-AzureRmSubscription -SubscriptionId $Conn.SubscriptionID

#please change below as needed
$VMLocalAdminUser = ""
#please change below as needed
$VMLocalAdminSecurePassword = ConvertTo-SecureString "" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);
$pubIP = "myPublicIpAddress" + $VMName        

New-AzureRMVm -Credential $Credential -ResourceGroupName $ResourceGroup -Name $VMName -Location $Location -VirtualNetworkName "myVnet" -SubnetName "mySubnet" -SecurityGroupName "myNetworkSecurityGroup" -PublicIpAddressName $pubIP -OpenPorts 80,3389 
#New-AzureRMVm -Credential $Credential -ResourceGroupName "flkelly-automation" -Name $VMName -Location $Location -VirtualNetworkName "myVnet" -SubnetName "mySubnet" -SecurityGroupName "myNetworkSecurityGroup" -PublicIpAddressName $pubIP -OpenPorts 80,3389 