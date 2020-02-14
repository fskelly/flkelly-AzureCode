#$miResourceGroup = "ManagedInstance1_RG"
$miResourceGroup = $(jq -r '.ManagedInstance.resourceGroup' settings.json) 
#$miName = "miedw"
$miName = $(jq -r '.ManagedInstance.name' settings.json) 
#$miLocation = 'northeurope'
$miLocation = $(jq -r '.ManagedInstance.location' settings.json) 
#$miVnetName ="myMIVnet"
$miVnetName = $(jq -r '.VNET.name' settings.json) 
#$miVnetPrefix = "10.0.0.0/16"
$miVnetPrefix = $(jq -r '.VNET.addressRange' settings.json) 
#$miDefaultSubnet = "Default"
$miDefaultSubnet = $(jq -r '.Subnet1.Name' settings.json) 
#$miDefaultSubnetPrefix = "10.0.0.0/24"
$miDefaultSubnetPrefix = $(jq -r '.Subnet1.addressRange' settings.json) 
#$miMISubnet = "ManagedInstances"
$miMISubnet =  $(jq -r '.Subnet2.Name' settings.json) 
#$miMISubnetPrefix = "10.0.1.0/24"
$miMISubnetPrefix = $(jq -r '.Subnet2.addressRange' settings.json) 
$subID = (Get-AzContext).Subscription.id

get-AzResourceGroup -ResourceGroupName $miResourceGroup  -ErrorVariable notPresent -ErrorAction SilentlyContinue

#check if RG exists
if ($notPresent)
{
    new-AzResourceGroup -Name $miResourceGroup -Location $miLocation
}
else 
{
    Write-output "RG already Exists"
}


$subnet1 = New-AzVirtualNetworkSubnetConfig -Name $miDefaultSubnet -AddressPrefix $miDefaultSubnetPrefix
$subnet2 = New-AzVirtualNetworkSubnetConfig -Name $miMISubnet -AddressPrefix $miMISubnetPrefix
New-AzVirtualNetwork -Name $miVnetName -ResourceGroupName $miResourceGroup -Location $miLocation -AddressPrefix $miVnetPrefix -Subnet $subnet1,$subnet2

##route Table
$scriptUrlBase = 'https://raw.githubusercontent.com/Microsoft/sql-server-samples/master/samples/manage/azure-sql-db-managed-instance/prepare-subnet'

$parameters = @{
    subscriptionId = $subID
    resourceGroupName = $miResourceGroup
    virtualNetworkName = $miVnetName
    subnetName = $miMISubnet
    }

Invoke-Command -ScriptBlock ([Scriptblock]::Create((iwr ($scriptUrlBase+'/prepareSubnet.ps1?t='+ [DateTime]::Now.Ticks)).Content)) -ArgumentList $parameters

$AdminUser = $(jq -r '.LoginInformation.username' settings.json)
$password = $(jq -r '.LoginInformation.password' settings.json)
#$AdminSecurePassword = ConvertTo-SecureString 'PASSWORD' -AsPlainText -Force
$AdminSecurePassword = ConvertTo-SecureString $password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminSecurePassword);

$miSubnetID = ((get-azvirtualnetwork -name $miVnetName -ResourceGroupName $miResourceGroup).Subnets | Where-Object {$_.Name -eq $miMISubnet}).ID

##core count - please use 8 / 16 / 24 / 32 / 40 / 64 / 80
#$coreCount = "8"
$coreCount = $(jq -r '.MIConfig.coreCount' settings.json)

## storage size for MI
#$miStorageSize = "256"
$miStorageSize = $(jq -r '.MIConfig.storageSize' settings.json)

## set SKU - please use GP-Gen4 / GP_Gen5 / BC_Gen4 / BC_Gen5
#$sku = "GP-Gen5"
$sku = $(jq -r '.MIConfig.sku' settings.json)

#azure rm
#New-AzureRmSqlInstance -Name $miName -ResourceGroupName $miResourceGroup -SkuName GP_Gen5 -SubnetId $miSubnetID -VCore $coreCount -Location $miLocation -AdministratorCredential $Credential -LicenseType 'LicenseIncluded' -StorageSizeInGB $miStorageSize -verbose

#az code
New-AzSqlInstance -Name $miName -ResourceGroupName $miResourceGroup -SkuName GP_Gen5 -SubnetId $miSubnetID -VCore $coreCount -Location $miLocation -AdministratorCredential $Credential -LicenseType 'LicenseIncluded' -StorageSizeInGB $miStorageSize -verbose