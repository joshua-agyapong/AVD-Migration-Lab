param(
    [Parameter(Mandatory=$true)] [string] $ResourceGroup,
    [Parameter(Mandatory=$true)] [string] $Location,
    [Parameter(Mandatory=$true)] [string] $HostPoolName,
    [string] $WorkspaceName = "AVD-Workspace01",
    [string] $DesktopAppGroupName = "AVD-Desktop-Group",
    [string] $RemoteAppGroupName = "AVD-RApp-Group",
    [string] $VNetName = "AVD-VNet",
    [string] $SubnetName = "default",
    [string] $VmSize = "Standard_B2s",
    [string] $VmAdminUser = "avdadmin",
    [string] $VmAdminPassword = ""
)

$ErrorActionPreference = "Stop"

if (-not (Get-Module -ListAvailable -Name Az.DesktopVirtualization)) {
    Install-Module Az.DesktopVirtualization -Scope CurrentUser -Force
}
if (-not (Get-AzContext)) {
    Connect-AzAccount | Out-Null
}

# Ensure Resource Group
$rg = Get-AzResourceGroup -Name $ResourceGroup -ErrorAction SilentlyContinue
if (-not $rg) {
    New-AzResourceGroup -Name $ResourceGroup -Location $Location | Out-Null
}

# Network (expects VNet/Subnet to exist; create minimal if missing)
$vnet = Get-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroup -ErrorAction SilentlyContinue
if (-not $vnet) {
    $subnetCfg = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix "10.0.1.0/24"
    $vnet = New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroup -Location $Location -AddressPrefix "10.0.0.0/16" -Subnet $subnetCfg
}
$subnetId = ($vnet.Subnets | Where-Object {$_.Name -eq $SubnetName}).Id

# Host Pool
$hp = New-AzWvdHostPool -ResourceGroupName $ResourceGroup -Name $HostPoolName -Location $Location -HostPoolType "Pooled" -LoadBalancerType "BreadthFirst" -PreferredAppGroupType "Desktop"

# Workspace
$ws = New-AzWvdWorkspace -ResourceGroupName $ResourceGroup -Name $WorkspaceName -Location $Location

# Application Groups
$dag = New-AzWvdApplicationGroup -ResourceGroupName $ResourceGroup -Name $DesktopAppGroupName -HostPoolArmPath $hp.Id -Location $Location -ApplicationGroupType "Desktop"
$rag = New-AzWvdApplicationGroup -ResourceGroupName $ResourceGroup -Name $RemoteAppGroupName -HostPoolArmPath $hp.Id -Location $Location -ApplicationGroupType "RemoteApp"

# Link App Groups to Workspace
New-AzWvdWorkspaceAssociation -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ApplicationGroupPath $dag.Id | Out-Null
New-AzWvdWorkspaceAssociation -ResourceGroupName $ResourceGroup -WorkspaceName $WorkspaceName -ApplicationGroupPath $rag.Id | Out-Null

# Create simple Session Host VM
$vmName = "$($HostPoolName)-VM01"
$imagePublisher = "microsoftwindowsdesktop"
$imageOffer = "windows-11"
$imageSku = "win11-23h2-avd"

$ip = New-AzPublicIpAddress -Name "$vmName-ip" -ResourceGroupName $ResourceGroup -Location $Location -AllocationMethod Static -Sku Standard
$nic = New-AzNetworkInterface -Name "$vmName-nic" -ResourceGroupName $ResourceGroup -Location $Location -SubnetId $subnetId -PublicIpAddress $ip

$cred = if ($VmAdminPassword) { New-Object System.Management.Automation.PSCredential ($VmAdminUser,(ConvertTo-SecureString $VmAdminPassword -AsPlainText -Force)) } else { $null }

$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $VmSize |
  Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate |
  Set-AzVMSourceImage -PublisherName $imagePublisher -Offer $imageOffer -Skus $imageSku -Version "latest" |
  Add-AzVMNetworkInterface -Id $nic.Id

New-AzVM -ResourceGroupName $ResourceGroup -Location $Location -VM $vmConfig | Out-Null

Write-Host "Core AVD resources created. Publish RemoteApps with scripts/publish-remoteapp.ps1"
