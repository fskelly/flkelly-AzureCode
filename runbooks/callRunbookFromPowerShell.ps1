$uri = "https://s2events.azure-automation.net/webhooks?token=Ld1nmehzUyMJ5tbx8cV5FvQdSY1Au4mfaOm4FtQ%2bZ3k%3d"

$VMName = Read-Host "Please provide VM Name"
$VMLocation = Read-Host "Please provide VM Location"
$VMResourceGroup = Read-Host "Please provide VM RG"

$rqbody  = @(
            @{ VMName=$VMName;Location=$VMLocation;ResourceGroup=$VMResourceGroup}
        )
$body = ConvertTo-Json -InputObject $rqbody
$header = @{ from="flkelly - Azure Guy"}

$response = Invoke-WebRequest -Method Post -Uri $uri -Body $body -Headers $header
$jobid = (ConvertFrom-Json ($response.Content)).jobids[0]

Write-Host "Job id: $jobid" 