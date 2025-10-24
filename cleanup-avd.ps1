param(
    [Parameter(Mandatory=$true)] [string] $ResourceGroup
)

$ErrorActionPreference = "Stop"

if (-not (Get-AzContext)) {
    Connect-AzAccount | Out-Null
}

Remove-AzResourceGroup -Name $ResourceGroup -Force -AsJob
Write-Host "Cleanup started. Check the job for progress."
