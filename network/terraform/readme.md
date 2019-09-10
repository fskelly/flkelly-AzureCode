# How to use this process

This complete process can be run from the [Azure Cloud Shell](https://shell.azure.com), [Terraform](https://www.terraform.io) is built-in.

First use my terraform file [main.tf](/terraform/runbooks/main.tf) to deploy the runbook and update the [variables.tf](/terraform/runbooks/variables.tf) as needed for your deployment.

Then use this [link](https://docs.microsoft.com/en-us/azure/automation/automation-webhooks) to add the "webhook" component to allow for external connectivity. [Postman](https://www.getpostman.com/) works really well for "posting" the required information. You can also use [PowerShell](https://github.com/fskelly/flkelly-AzureCode/blob/master/runbooks/powershell/callRunbookFromPowerShell.ps1) </br>
</br>
*You can override vraiables like such*
```bash
terraform init
terraform plan -out runbook.plan
-var 'automationrg_location=westeurope' \
-var 'automationrg_name=testautomationrg' \
-var 'automation_account_name=automation-account' \
-var 'automation_runbook_name=mytestrunbbok'
terraform apply "runbook.plan"
```
