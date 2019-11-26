### ARM Variables, use an SPN here that has the required access
variable "ARM_SUBSCRIPTION_ID" {
    default=""
}
variable "ARM_CLIENT_ID" {
    default=""
}
variable "ARM_CLIENT_SECRET" {
    default=""
}
variable "ARM_TENANT_ID" {
    default=""
}

##no defaults defined - only placholders reamin

###==========================KEYVAULT=============================================
###Import data variables from the KEYVAULT
##URI for Azure Keyvault
variable "keyvault_vault_uri" {
  description = "The prefix used for all resources in this example"
  default = "https://xxx.vault.azure.net/"
}
## Azure Keyvaulkt name and resource group name
data "azurerm_key_vault" "kv1" {
  name                = "xxx"
  resource_group_name = "yyy"
}
##keyvault secret properties
data "azurerm_key_vault_secret" "myUsername" {
  name = "username_key"
  key_vault_id = "${data.azurerm_key_vault.kv1.id}"
}
##keyvault secret properties
data "azurerm_key_vault_secret" "myPassword" {
  name = "password_key"
  key_vault_id = "${data.azurerm_key_vault.kv1.id}"
}
###======================END-KEYVAULT=============================================

###==================================VARIABLES============================
###Define required varaibles, can be overrriden as needed
##Add other regions as needed
variable "locations" {
    type = "map"
    default = {
        "WEU"  = "westeurope"
        "weu"  = "westeurope"
        "ZAN" = "southafricanorth"
        "zan" = "southafricanorth"        
        "NEU" = "northeurope"
        "neu" = "northeurope"
    }
}

##prefix for resource group names
variable "prefix" {
  description = "The prefix used for all resources in this example"
  default = "prefix"
}

##input variable for the locations map
variable "location" {
  description = "refer to variable locations for expected values"
}

##Pre-defined tags to be applied
variable "tags" {
  description = "Tags that will be applied to the resources"
  type = "map"

  default = {
    owner = "flkelly"
    createdby = "terraform"
  }
}

##Resource Group for VMs
variable "vm_resource_group_name" {
  description = "Name of the resource Group that will house the vms"
  default = "vms"
}

##resource group name for ntworking components, NICs placed in this Resource Group
variable "net_resource_group_name" {
  description = "Name of the resource Group that will house the networking components"
  default = "net"
}

#variable "admin_ssh_key_data" {}

#variable "home_gateway_shared_key" {
#  default = "1cb70637b2cd1ca8959fc0668ef6fb55"
#}

##ip range for "on-prem"
variable "on_prem_range" {
  description ="used to define your on-prem range"
  default = "192.168.0.0/16"
}

## WAN ip for VPN device "on-prem"
variable "home_gateway_public_address" {
  description = "your public ip address of your on-prem vpn device"
  default = "w.x.y.z" # NB you need to change this to your actual home gateway/vpn-device public address.
}

variable "vm_szie" {
  description = "default vm size"
  default = "Standard_B1s"
  
}

###==============================END-VARIABLES============================