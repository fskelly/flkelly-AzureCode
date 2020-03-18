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