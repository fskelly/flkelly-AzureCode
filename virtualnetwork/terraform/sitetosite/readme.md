# Site to Site Terraform Read Me

Full documentation can be found for creating an SPN for Terraform [here](https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html)

Below is a small snippet specifically for [AZ CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)

```bash
az login
az account list

#substitute your Subscription ID below
SUBSCRIPTION_ID=""
az account set --subscription ${SUBSCRIPTION_ID}
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/SUBSCRIPTION_ID"
```

Please keep the output safe, the "Password" will be only be displayed this one time and not again. You can [reset](https://docs.microsoft.com/en-us/cli/azure/ad/sp/credential?view=azure-cli-latest#az-ad-sp-credential-reset) the SPN password if needed. </br>

I also have a script for the creation of the required SPN [here](www.getlink.com

An example is below, please replace the required components, like the Public IP address, the "apply" will fail with the defaults within the .tf files, as these are meant to be placeholders. Many people forget to update this, so the example wth OVERRIDE the variables in [variables.tf](variables.tf) file

```bash
##from the ceation of the SPN, the values are needed below.
export ARM_CLIENT_ID=""
export ARM_CLIENT_SECRET=""
export ARM_SUBSCRIPTION_ID=""
export ARM_TENANT_ID=""

terraform init
##8.8.8.8 is a sample, we know that this is a public DNS Server
## weu is a region name I use as part of a map in the .tf files
terraform plan -var 'location=weu' -var 'prefix=terraform' -var 'home_gateway_public_address=8.8.8.8' -out mytest.plan
terraform apply mytest.plan
```
