# Using PowerShell Automation in Azure Runbook

Use this script in conjuction with PowerShell Runbook with Webhook to create a VM, code [here](/runbooks/powershell/createVMrunbook.ps1)

## Postman Sample

POST `https://s2events.azure-automation.net/webhooks?token=""` (Replace "" with token created as part of creating the Webhok for your Runbook), let us say your token is "12345abcde".

POST `https://s2events.azure-automation.net/webhooks?token=12345abcde`

Sample `JSON` below

```json
{
    "VMName":  "apriltest",
    "Location":  "WestEurope",
    "ResourceGroup": "flkellyCKADCluster"
}
```

You will an output like this.

```json
{
    "JobIds": [
        "21191da4-76a5-4576-a24f-6149b478cf36"
    ]
}
```

You can then track the progress of this request in the [Azure Portal](https://portal.azure.com) on the runbook overview tab, you can then click of the most recent runbook and dive into the detail of it.
![Runbook Overview](/runbooks/powershell/runbook_overview.png)

And then see some more details like this
![Runbook Job Details](/runbooks/powershell/runbook_job_details.png)
