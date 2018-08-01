<#
	.SYNOPSIS
		Exports the VM sizes currently available in Azure to a CSV file.
	
	.DESCRIPTION
		
	
	.EXAMPLE
		Export-AzureVmSizes.ps1 -Path ./VMSize.csv
		
		This command will prompt for the Azure credentials and will export the available VM sizes from all Azure locations to VMSize.csv, using comma (,) as CSV delimiter.
		
	.EXAMPLE
		Export-AzureVmSizes.ps1 -Path ./VMSize.csv -CSVDelimiter ";"
		
		This command will prompt for the Azure credentials and will export the available VM sizes from all Azure locations to VMSize.csv, using semicolon (;) as CSV delimiter.
		
	.EXAMPLE
		Export-AzureVMSizes.ps1 -Path ./VMSizeWE.csv -Location westeurope
	
		This command will prompt for the Azure credentials and will export the available VM sizes from location West Europe and saves it to VMSizeWE.csv, using comma (,) as CSV delimiter.
	
	.PARAMETER Path
		Specifies the path to the CSV output file.
	
	.PARAMETER Credential
		The credentials to use when connecting to Azure. If this parameter is omitted, the script will prompt for credentials by using the Login-AzureRMAccount cmdlet.
	
	.PARAMETER Location
		Specifies the Azure DataCenter location to retrieve available VM sizes for. If this parameter is omitted, all locations are retrieved and a matrix output is generated. This can either be the location name (eg. westeurope) or the location display name (eg. "West Europe").
	
	.PARAMETER CSVDelimiter
		Specifies a delimiter to separate the property values. The default is a comma (,). Enter a character, such as a colon (:). To specify a semicolon (;), enclose it in quotation marks.
	
	.NOTES
		Title:          Export-AzureVMSizes.ps1
		Author:         Floris van der Ploeg
		Created:        2016-10-25
		ChangeLog:
			2016-10-25  Initial version
#>

<#	Parameters #>
[CmdletBinding()]
Param
(
	[Parameter(Mandatory=$true,Position=0)]
	[String]$Path,
	[Parameter(Mandatory=$false,Position=1)]
	[Management.Automation.PSCredential]$Credential,
	[Parameter(Mandatory=$false,Position=2)]
	[String]$Location,
	[Parameter(Mandatory=$false,Position=3)]
	[Char]$CSVDelimiter = ","
)

<#	Functions #>
	Function Write-Log
	{
		Param
		(
			[Parameter(Mandatory=$true,Position=0)]
			[string]$Value,
			[Parameter(Mandatory=$false,Position=1)]
			[string]$Color = "White"
		)
		
		Write-Host ("[{0:yyyy-MM-dd HH:mm:ss}] {1}" -f (Get-Date),$Value) -ForegroundColor $Color
	}

<#	Global parameters #>
	$Global:ScriptPath			= Split-Path $MyInvocation.MyCommand.Path -Parent
	$Global:ScriptName			= Split-Path $MyInvocation.MyCommand.Path -Leaf
	
<#	Main script #>
	Write-Log -Value "Logging in to Azure" -Color Green
	If ($Credential -eq $null)
	{
		$AZAccount = Login-AzureRMAccount
	}
	Else
	{
		$AZAccount = Login-AzureRMAccount -Credential $Credential
	}

	If ($AZAccount -ne $null)
	{
		# Check if the location parameter is set
		Write-Log -Value "Checking Azure DataCenter locations" -Color Yellow
		If ($Location -ne $null -and $Location -ne "")
		{
			$Locations = Get-AzureRmLocation -WarningAction SilentlyContinue | Where-Object {$_.Location -eq $Location -or $_.DisplayName -eq $Location} 
		}
		Else
		{
			$Locations = Get-AzureRmLocation -WarningAction SilentlyContinue
		}
		
		If ($Locations.Count -ge 1)
		{
			# Create the data table to store the VM sizes
			$VMSizeTable = New-Object -TypeName System.Data.DataTable
			$VMSizeTable.Columns.Add("VM size name") | Out-Null
			$VMSizeTable.Columns.Add("Number of CPU cores") | Out-Null
			$VMSizeTable.Columns.Add("Memory in MB") | Out-Null
			$VMSizeTable.Columns.Add("Max data disk count") | Out-Null
			$VMSizeTable.Columns.Add("OS disk size in MB") | Out-Null
			$VMSizeTable.Columns.Add("Resource disk size in MB") | Out-Null
			
			# Process each location
			ForEach ($LocationItem in $Locations)
			{
				Write-Log -Value ("Processing location {0}" -f $LocationItem.DisplayName)
			
				# Add the location as column
				$LocationColumnName = "{0} ({1})" -f $LocationItem.DisplayName,$LocationItem.Location
				$VMSizeTable.Columns.Add($LocationColumnName) | Out-Null

				# Get the VM sizes
				ForEach ($VMSizeItem in (Get-AzureRmVmSize -Location $LocationItem.Location))
				{
					# Check if the size already has been added to the table
					$Rows = $VMSizeTable.Select(("[VM size name] = '{0}'" -f $VMSizeItem.Name))
					If ($Rows.Count -eq 0)
					{
						# Create a new row
						$Row = $VMSizeTable.NewRow()
						
						# Fill the values of each column
						$Row["VM size name"] = $VMSizeItem.Name
						$Row["Number of CPU cores"] = $VMSizeItem.NumberOfCores
						$Row["Memory in MB"] = $VMSizeItem.MemoryInMB
						$Row["Max data disk count"] = $VMSizeItem.MaxDataDiskCount
						$Row["OS disk size in MB"] = $VMSizeItem.OSDiskSizeInMB
						$Row["Resource disk size in MB"] = $VMSizeItem.ResourceDiskSizeInMB
						$Row[$LocationColumnName] = "X"
						
						# Add the row to the table
						$VMSizeTable.Rows.Add($Row)
					}
					Else
					{
						# Update the existing row
						$Rows[0][$LocationColumnName] = "X"
					}
				}
			}
			
			# Export the datatable to CSV
			Write-Log -Value ("Exporting data to {0}" -f $Path) -Color Green
			$VMSizeTable | Export-Csv -Path $Path -NoTypeInformation -Delimiter $CSVDelimiter
		}
		Else
		{
			# Azure location not found
			Write-Error -Message ("Defined Azure location {0} is not valid" -f $Location)
		}
	}
	Else
	{
		# Could not log on to Azure
		Write-Error -Message "Could not logon to Azure"
	}