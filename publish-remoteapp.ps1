param(
    [Parameter(Mandatory=$true)] [string] $ResourceGroup,
    [Parameter(Mandatory=$true)] [string] $HostPoolName,
    [Parameter(Mandatory=$true)] [string] $AppGroupName,
    [Parameter(Mandatory=$true)] [string] $AppFriendlyName,
    [Parameter(Mandatory=$true)] [string] $AppPath
)

$ErrorActionPreference = "Stop"

if (-not (Get-Module -ListAvailable -Name Az.DesktopVirtualization)) {
    Install-Module Az.DesktopVirtualization -Scope CurrentUser -Force
}
if (-not (Get-AzContext)) {
    Connect-AzAccount | Out-Null
}

$ag = Get-AzWvdApplicationGroup -ResourceGroupName $ResourceGroup -Name $AppGroupName

New-AzWvdApplication `
  -ResourceGroupName $ResourceGroup `
  -ApplicationGroupName $AppGroupName `
  -Name ($AppFriendlyName -replace '\s','') `
  -FriendlyName $AppFriendlyName `
  -FilePath $AppPath `
  -CommandLineSetting "DoNotAllow" | Out-Null

Write-Host "RemoteApp '$AppFriendlyName' published."
