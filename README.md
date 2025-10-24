# AVD Migration from Citrix (Simulated) — Hands‑On Lab

This repo shows a real‑world style migration from a **legacy Citrix‑style desktop** (simulated in AWS) to **Azure Virtual Desktop (AVD)**. It follows what you built:
- Azure VNet and subnet
- AVD Host Pool, Workspace, and Session Host (Windows 11 Enterprise multi‑session)
- Entra ID join
- Public RDP for troubleshooting
- Tags for cost/governance
- RemoteApp publishing
- Basic automation with PowerShell

---

## Repo quick facts
- **Project:** AVD‑Migration
- **Environment:** Lab
- **Region:** East US
- **Resource Group:** `AVD-Migration-RG`
- **VNet/Subnet:** `AVD-VNet` / `10.0.1.0/24`
- **Host Pool:** `AVD-HostPool01`
- **Workspace:** `AVD-Workspace01`
- **VM name prefix:** `AVD-VM`
- **Admin:** `avdadmin` (choose your own password)

---

## Architecture (high‑level)

```
Users (Remote Desktop client)
        |
        v
AVD Workspace  —  Desktop + RemoteApp
        |
        v
AVD Host Pool (Windows 11 multi‑session VMs)
        |
        v
AVD-VNet (10.0.0.0/16)  -> Subnet 10.0.1.0/24
        |
        v
Azure Services (Entra ID)
```

---

## Prerequisites
- Azure subscription (trial/student is fine)
- Rights to create resource groups, VNets, and VMs
- PowerShell 7+ or **Azure Cloud Shell**

Install modules (if running locally):
```pwsh
Install-Module Az -Scope CurrentUser -Force
Install-Module Az.DesktopVirtualization -Scope CurrentUser -Force
Connect-AzAccount
```

---

## Step‑by‑step (what you actually did)

### 1) Create network
- RG: `AVD-Migration-RG`
- VNet: `AVD-VNet` (`10.0.0.0/16`)
- Subnet: `10.0.1.0/24`
- Leave Bastion/Firewall/DDOS off for lab

**Screenshot to capture:** `docs/images/01-vnet-subnet.png`

### 2) Create Host Pool
- Host pool: `AVD-HostPool01`
- Type: **Pooled**
- Load balancing: **Breadth-first**

**Screenshot:** `docs/images/02-hostpool-overview.png`

### 3) Add Session Host VM
- Add virtual machines: **Yes**
- Image: **Windows 11 Enterprise multi‑session (23H2)**
- Size: **Standard B2s** (or D2as v5)
- Count: 1
- Network: `AVD-VNet` / `default`
- Public inbound ports: **Yes** (RDP 3389) for lab
- Join: **Microsoft Entra ID**
- Admin: `avdadmin`

**Screenshot:** `docs/images/03-sessionhost-vm.png`

### 4) Workspace link
- Register desktop app group: **Yes**
- Workspace: **Create new → `AVD-Workspace01`**

**Screenshot:** `docs/images/04-workspace.png`

### 5) Management and Tags
- Managed Identity: off
- Diagnostics: off
- Tags (example):
  - `Project=AVD-Migration`
  - `Environment=Lab`
  - `Owner=JoshuaAgyapong`
  - `Department=IT`
  - `Purpose=Citrix-to-AVD Migration Practice`

**Screenshot:** `docs/images/05-tags.png`

### 6) Deploy
- Click **Review + create → Create**
- Wait for **Deployment complete**

**Screenshot:** `docs/images/06-deploy-complete.png`

### 7) Validate user connection
- Install **Remote Desktop** client on Windows
- Sign in with your Entra ID test user
- Launch the Desktop from `AVD-Workspace01`

**Screenshot:** `docs/images/07-user-connected.png`

### 8) Publish a RemoteApp (Notepad)
Use the script below or the Azure portal to publish Notepad as a RemoteApp.

**Screenshot:** `docs/images/08-remoteapp-notepad.png`

---

## Automation

### Create core AVD resources
```pwsh
./scripts/create-avd.ps1 `
  -ResourceGroup AVD-Migration-RG `
  -Location "East US" `
  -HostPoolName AVD-HostPool01 `
  -VmSize "Standard_B2s"
```

### Publish Notepad RemoteApp
```pwsh
./scripts/publish-remoteapp.ps1 `
  -ResourceGroup AVD-Migration-RG `
  -HostPoolName AVD-HostPool01 `
  -AppGroupName AVD-RApp-Group `
  -AppFriendlyName "Notepad" `
  -AppPath "C:\Windows\System32\notepad.exe"
```

### Cleanup (optional)
```pwsh
./scripts/cleanup-avd.ps1 -ResourceGroup AVD-Migration-RG
```

---

## What this proves (resume bullets)

- Deployed **Azure Virtual Desktop** (host pool, session host, workspace) in Azure.
- Joined session host to **Microsoft Entra ID** and enabled **RDP** for admin troubleshooting.
- Implemented **Published Applications** using **AVD RemoteApp** (Notepad).
- Used **PowerShell automation** with `Az` and `Az.DesktopVirtualization` modules.
- Applied **enterprise‑style tags** for governance and cost tracking.
- Captured deployment **evidence** with step‑by‑step screenshots.

---

## Screenshot checklist
See `docs/Screenshots.md` for the full list and file names. Replace the placeholder files in `docs/images/` with your real screenshots and commit.

---

## License
MIT
