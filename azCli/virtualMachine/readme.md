# Creating a Linux Virtual Machine in existing Subnet

Use below code within the [Azure Cloud Shell](https://shell.azure.com) or [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) to create a Linux Virtual Machine (VM), example values are provided next to parameters. The Subscription ID is your Subscription ID. This particular exmaple uses a VNet already created by referencing the Virtual Network (VNet) id on this line `SUBNET_ID=$(az network vnet subnet show --resource-group ${RG_NAME} --name ${SUBNET_NAME} --vnet-name ${VNET_NAME} --query id -o tsv)`. To create the VNet and Subnet, please look [here](https://github.com/fskelly/flkelly-AzureCode/blob/master/azCli/network/createVNetandSubnet.md)

```bash
SUB_ID="" #EXAMPLE XX-YYYY-ZZZ

RG_NAME="" #EXAMPLE "RG1"
VNET_RG_NAME="" #IF vnet is in different RG

REGION="" #EXAMPLE "southafricanorth"

VM_NAME="" #EXAMPLE VM1
VM_SIZE="" #EXAMPLE Standard_A4
VM_ADMIN_USER="" #EXAMPLE vmadmin
VM_ADMIN_PASSWORD="" #EXAMPLE P@55w0rd!

VM_IMAGE="" #EXAMPLE UbuntuLTS
STORAGE_SKU="" #EXAMPLE Standard_LRS"

VNET_NAME="" #EXAMPLE VNET1
SUBNET_NAME="" #EXAMPLE SUBNET1
VNET_PREFIX="" #EXAMPLE 172.16.0.0/16
SUBNET_PREFIX="" #EXAMPLE 172.16.1.0/24

az account set --subscription ${SUB_ID}
SUBNET_ID=$(az network vnet subnet show --resource-group ${VNET_RG_NAME} --name ${SUBNET_NAME} --vnet-name ${VNET_NAME} --query id -o tsv)
az vm create --resource-group ${RG_NAME} --name ${VM_NAME} --admin-username ${VM_ADMIN_USER} --admin-password ${VM_ADMIN_PASSWORD} --image ${VM_IMAGE} --storage-sku ${STORAGE_SKU} --subnet ${SUBNET_ID} --location ${REGION}
```
