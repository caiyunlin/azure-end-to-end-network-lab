# Quick Start Guide

This guide will help you deploy the Azure End-to-End Networking Lab in under 5 minutes.

## Prerequisites

✅ Azure subscription  
✅ Azure CLI installed  
✅ Bash or PowerShell terminal  

## Option 1: One-Click Deploy (Easiest)

1. Click this button:

   [![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcaiyunlin%2Fazure-end-to-end-network-lab%2Fmain%2Fazuredeploy.json)

2. Fill in:
   - **Resource Group**: Create new (e.g., `rg-netlab`)
   - **Location**: `East US`
   - **VM Admin Password**: `P@ssw0rd123!` (or your strong password)

3. Click **Review + Create** → **Create**

4. Wait 20-30 minutes ☕

5. Done! Access your resources from the Outputs tab.

---

## Option 2: PowerShell (Windows)

```powershell
# 1. Clone repo
git clone https://github.com/caiyunlin/azure-end-to-end-network-lab.git
cd azure-end-to-end-network-lab

# 2. Login to Azure
az login

# 3. Deploy
$password = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
.\deploy.ps1 -VmAdminPassword $password
```

---

## Option 3: Bash (Linux/Mac)

```bash
# 1. Clone repo
git clone https://github.com/caiyunlin/azure-end-to-end-network-lab.git
cd azure-end-to-end-network-lab

# 2. Make executable
chmod +x deploy.sh

# 3. Login to Azure
az login

# 4. Deploy
./deploy.sh -p "P@ssw0rd123!"
```

---

## What Gets Deployed?

- ✅ Azure Front Door (global CDN)
- ✅ Application Gateway (load balancer)
- ✅ Azure Firewall (network security)
- ✅ Virtual Network (10.0.0.0/16)
- ✅ App Service (web app)
- ✅ Ubuntu VM (backend server)
- ✅ Azure Bastion (secure access)

**Total Resources:** ~20 Azure resources

---

## After Deployment

Access your endpoints from deployment outputs:

```bash
# Get outputs
az deployment group show \
  --name <deployment-name> \
  --resource-group rg-netlab \
  --query properties.outputs
```

**Test your deployment:**
```bash
# Test Front Door
curl https://<frontdoor-endpoint>.azurefd.net

# Test App Service
curl https://<app-name>.azurewebsites.net
```

---

## Next Steps

- 📖 Read [ARCHITECTURE.md](ARCHITECTURE.md) for detailed design
- 🐛 Having issues? See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- 🧹 When done: `az group delete --name rg-netlab --yes`

---

## Cost Warning ⚠️

This lab costs approximately **$1,255/month** if left running.

**Save money:**
- Stop VM when not in use
- Delete resources after testing
- Use lower-tier SKUs for learning

```bash
# Stop VM to save costs
az vm deallocate --resource-group rg-netlab --name netlab-vm
```

---

## Need Help?

- 📚 [Full README](README.md)
- 🏗️ [Architecture Details](ARCHITECTURE.md)
- 🔧 [Troubleshooting Guide](TROUBLESHOOTING.md)
- 💬 [Open an Issue](https://github.com/caiyunlin/azure-end-to-end-network-lab/issues)
