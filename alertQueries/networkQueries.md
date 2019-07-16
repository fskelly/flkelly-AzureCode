##based on having AzureActivityLogs being sent to a Workspace

## NSG Creation
AzureActivity
| where OperationName == "Create or Update Security Rule"
| where ActivityStatusValue == "Succeeded" 
|project OperationName , ResourceGroup , Resource ,Caller, TimeGenerated

## NSG Modification
AzureActivity
| where OperationName == "Create or Update Network Security Group"
| where ActivityStatusValue == "Succeeded" 
|project OperationName , ResourceGroup , Resource ,Caller, TimeGenerated

## VNET Creation
AzureActivity
| where OperationName == "Create or Update Virtual Network"
| where ActivityStatusValue == "Succeeded" 
|project OperationName , ResourceGroup , Resource ,Caller, TimeGenerated

## Subnet Creation
AzureActivity
| where OperationName == "Create or Update Virtual Network Subnet"
| where ActivityStatusValue == "Succeeded" 
|project OperationName , ResourceGroup , Resource ,Caller, TimeGenerated

## VNET Peering Creation
AzureActivity
| where OperationName == "Create or Update Virtual Network Peering"
| where ActivityStatusValue == "Succeeded" 
|project OperationName , ResourceGroup , Resource ,Caller, TimeGenerated
