#PROVIDER AZURE
provider "azurerm" {
    subscription_id = "${var.ARM_SUBSCRIPTION_ID}"
    client_id       = "${var.ARM_CLIENT_ID}"
    client_secret   = "${var.ARM_CLIENT_SECRET}"
    tenant_id       = "${var.ARM_TENANT_ID}"
    version         = "1.24.0"
}

resource "azurerm_resource_group" "vmrg" {
#  name     = "${var.vm_resource_group_name}" # NB this name must be unique within the Azure subscription.
  name     = "${var.prefix}-${var.location}-vms1"
  location = "${var.locations["${var.location}"]}"
  tags     = "${var.tags}"
}
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-${var.location}-net1" # NB this name must be unique within the Azure subscription.
  location = "${var.locations["${var.location}"]}"
  tags     = "${var.tags}"
}

# NB this generates a single random number for the resource group.
resource "random_id" "example" {
  keepers = {
    resource_group = "${azurerm_resource_group.rg.name}"
  }

  byte_length = 10
}

resource "azurerm_storage_account" "diagnostics" {
  # NB this name must be globally unique as all the azure storage accounts share the same namespace.
  # NB this name must be at most 24 characters long.
  name = "diag${random_id.example.hex}"

  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${var.locations["${var.location}"]}"
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "vnet1"
  address_space       = ["10.101.0.0/16"]
  location            = "${var.locations["${var.location}"]}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"                           # NB you MUST use this name. See the VPN Gateway FAQ.
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet1.name}"
  address_prefix       = "10.101.1.0/27"
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  virtual_network_name = "${azurerm_virtual_network.vnet1.name}"
  address_prefix       = "10.101.2.0/24"
}

# NB do not try to get the azurerm_public_ip.gateway.fqdn value because it always resolves to 255.255.255.255. instead, the gateway address is obtained with make show-vpn-client-configuration.
resource "azurerm_public_ip" "gatewayip" {
  name                         = "gateway"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  location                     = "${var.locations["${var.location}"]}"
  allocation_method            = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = "gateway"
  location            = "${var.locations["${var.location}"]}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  type          = "Vpn"
  vpn_type      = "RouteBased"
  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"     # NB Basic sku does not support IKEv2.

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = "${azurerm_public_ip.gatewayip.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.gateway.id}"
  }

  vpn_client_configuration {
    address_space        = ["172.31.0.0/16"]
    vpn_client_protocols = ["SSTP", "IkeV2"] # NB IKEv2 is not supported by the Basic sku gateway.

    #root_certificate {
    #  name             = "example-ca"
    #  public_cert_data = "${base64encode(file("shared/example-ca/example-ca-crt.der"))}"
    #}
  }
}

resource "azurerm_local_network_gateway" "home" {
  name                = "home"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.locations["${var.location}"]}"
  gateway_address     = "${var.home_gateway_public_address}"
  address_space       = ["${var.on_prem_range}"]
}

resource "azurerm_virtual_network_gateway_connection" "home" {
  name                = "home"
  location            = "${var.locations["${var.location}"]}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.gateway.id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.home.id}"

  #variable can be used instead of a randomized key "${var.home_gateway_shared_key}"
  shared_key = "${random_string.home_gateway_shared_key.result}"

  # NB there is no way to change the ike sa lifetime from its fixed value of 28800 seconds.
  # see https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpn-devices#ipsec
  # see https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-ipsecikepolicy-rm-powershell
  # see https://www.terraform.io/docs/providers/azurerm/r/virtual_network_gateway_connection.html
  ipsec_policy {
    dh_group         = "DHGroup2048"
    ike_encryption   = "AES128"
    ike_integrity    = "SHA256"
    ipsec_encryption = "AES128"
    ipsec_integrity  = "SHA256"
    pfs_group        = "PFS2048"
    sa_datasize      = 104857600  # [KB] (104857600KB = 100GB)
    sa_lifetime      = 27000      # [Seconds] (27000s = 7.5h)
  }
}

resource "azurerm_network_interface" "ubuntu" {
  name                = "${var.location}-ubuntu"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.locations["${var.location}"]}"

  ip_configuration {
    name                          = "ubuntu"
    subnet_id                     = "${azurerm_subnet.backend.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.101.2.4" # NB Azure reserves the first four addresses in each subnet address range, so do not use those.
  }
}

resource "azurerm_virtual_machine" "ubuntu" {
  name                  = "${var.location}-ubuntu"
  resource_group_name   = "${azurerm_resource_group.vmrg.name}"
  location              = "${var.locations["${var.location}"]}"
  network_interface_ids = ["${azurerm_network_interface.ubuntu.id}"]
  vm_size               = "${var.vm_szie}"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name          = "ubuntu_os"
    caching       = "ReadWrite" # TODO is this advisable?
    create_option = "FromImage"

    #disk_size_gb      = "60" # this is optional. # TODO change this?
    managed_disk_type = "StandardSSD_LRS" # Locally Redundant Storage.
  }

  # see https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # NB this disk will not be initialized.
  #    so, you must format it yourself.
  # TODO add a provision step to initialize the disk.
  storage_data_disk {
    name              = "ubuntu_data"
    caching           = "ReadWrite"       # TODO is this advisable?
    create_option     = "Empty"
    disk_size_gb      = "10"
    lun               = 0
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name  = "ubuntu"
    #admin_username = "${var.admin_username}"
    #admin_password = "${var.admin_password}"
    admin_username = "${data.azurerm_key_vault_secret.myUsername.value}"
    admin_password = "${data.azurerm_key_vault_secret.myPassword.value}"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    #ssh_keys {
    #  path     = "/home/${var.admin_username}/.ssh/authorized_keys"
    #  key_data = "${var.admin_ssh_key_data}"
    #}
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = "${azurerm_storage_account.diagnostics.primary_blob_endpoint}"
  }
}

resource "azurerm_network_interface" "windows" {
  name                = "${var.location}-windows"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.locations["${var.location}"]}"

  ip_configuration {
    name                          = "windows"
    subnet_id                     = "${azurerm_subnet.backend.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.101.2.5" # NB Azure reserves the first four addresses in each subnet address range, so do not use those.
  }
}

resource "azurerm_virtual_machine" "windows" {
  name                  = "${var.location}-windows"
  resource_group_name   = "${azurerm_resource_group.vmrg.name}"
  location              = "${var.locations["${var.location}"]}"
  network_interface_ids = ["${azurerm_network_interface.windows.id}"]
  vm_size               = "${var.vm_szie}"

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name          = "windows_os"
    caching       = "ReadWrite" # TODO is this advisable?
    create_option = "FromImage"

    #disk_size_gb      = "60" # this is optional. # TODO change this?
    managed_disk_type = "StandardSSD_LRS" # Locally Redundant Storage.
  }

  # see https://docs.microsoft.com/en-us/azure/virtual-machines/windows/cli-ps-findimage
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  # NB this disk will not be initialized.
  #    so, you must format it yourself.
  # TODO add a provision step to initialize the disk.
  storage_data_disk {
    name              = "windows_data"
    caching           = "ReadWrite"       # TODO is this advisable?
    create_option     = "Empty"
    disk_size_gb      = "10"
    lun               = 0
    managed_disk_type = "StandardSSD_LRS"
  }

  os_profile {
    computer_name  = "windows"
    #admin_username = "${var.admin_username}"
    #admin_password = "${var.admin_password}"
    admin_username = "${data.azurerm_key_vault_secret.myUsername.value}"
    admin_password = "${data.azurerm_key_vault_secret.myPassword.value}"
  }

  os_profile_windows_config {
    provision_vm_agent = false
    enable_automatic_upgrades = false
    timezone = "GMT Standard Time"
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = "${azurerm_storage_account.diagnostics.primary_blob_endpoint}"
  }
}

resource "random_string" "home_gateway_shared_key" {
  length      = 30
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}


#### ==================OUTPUT SECTION====================================

#public ip will not be displayed due to Dynamic IP
output "gateway_ip_address" {
  value = "${azurerm_public_ip.gatewayip.ip_address}"
}

output "ubuntu_ip_address" {
  value = "${azurerm_network_interface.ubuntu.private_ip_address}"
}

output "windows_ip_address" {
  value = "${azurerm_network_interface.windows.private_ip_address}"
}

output "home_gateway_shared_key" {
  value = "${random_string.home_gateway_shared_key.result}"
}
