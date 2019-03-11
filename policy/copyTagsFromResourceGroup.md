Use this policy to copy tags from the "parent" Resource Group to the resources created within the Resourge Group. This will _**NOT**_ append existing resources within the resource group after creating this policy. In order to perfrom a task like that, you would need to use scripts, personaly I use PowerShell and have already started a script like this. These [script(s)](https://github.com/fskelly/flkelly-AzureCode/tree/master/powershell/azureTags) are just a start and would need to modified for you needs.

JSON for the policy to append Existing tags within a Resource Group to newly created items is as below.

```json
{
    "if": {
      "field": "tags.costCode",
      "exists": "false"
    },
    "then": {
      "effect": "append",
      "details": [
        {
          "field": "tags.costCode",
          "value": "[resourceGroup().tags.costCode]"
        }
      ]
    }
}
```