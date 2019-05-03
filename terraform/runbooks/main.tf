resource "azurerm_resource_group" "automationrg" {
  name     = "${var.automationrg_name}"
  location = "${var.automationrg_location}"
  tags = {
    environment = "testing",
    Internal = "true",
    CustomerFacing = "false"
  }
}

resource "azurerm_automation_account" "automationaccount" {
  name                = "${var.automation_account_name}"
  location            = "${azurerm_resource_group.automationrg.location}"
  resource_group_name = "${azurerm_resource_group.automationrg.name}"

  sku {
    name = "Basic"
  }
  tags = {
    environment = "testing",
    Internal = "true",
    CustomerFacing = "false"
  }
}

resource "azurerm_automation_runbook" "provisionvmrunbook" {
  name                = "${var.automation_runbook_name}"
  location            = "${azurerm_resource_group.automationrg.location}"
  resource_group_name = "${azurerm_resource_group.automationrg.name}"
  account_name        = "${azurerm_automation_account.automationaccount.name}"
  log_verbose         = "true"
  log_progress        = "true"
  description         = "This is a sample runbbok for creatting a vm using powershel and an api webhook"
  runbook_type        = "PowerShell"

  publish_content_link {
    uri = "https://raw.githubusercontent.com/fskelly/flkelly-AzureCode/master/runbooks/powershell/createVMrunbook.ps1"
  }
  tags = {
    environment = "testing",
    Internal = "true",
    CustomerFacing = "false"
  }
}