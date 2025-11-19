# Azure End-to-End Networking Lab

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcaiyunlin%2Fazure-end-to-end-network-lab%2Fmain%2Fazuredeploy.json)

End-to-end Azure networking lab featuring **Azure Front Door**, **Azure Firewall**, **Application Gateway**, **Virtual Network**, **App Service**, and **Virtual Machine**. This lab demonstrates a complete enterprise-grade network architecture with multiple layers of security and traffic management.

## 🏗️ Architecture Overview

This lab deploys the following Azure resources:

```
Internet
   │
   ↓
Azure Front Door (Global CDN & WAF)
   │
   ↓
Application Gateway (Regional Load Balancer)
   │
   ├─→ App Service (VNet Integrated)
   │
   ↓
Azure Firewall (Network Security)
   │
   ↓
Virtual Network
   ├─ AppGatewaySubnet (10.0.1.0/24)
   ├─ AzureFirewallSubnet (10.0.2.0/24)
   ├─ VMSubnet (10.0.3.0/24)
   ├─ AppServiceSubnet (10.0.4.0/24)
   └─ AzureBastionSubnet (10.0.5.0/24)
       │
       └─→ Virtual Machine (Ubuntu 22.04)
```

### Components

| Component | Purpose |
|-----------|---------|
| **Azure Front Door** | Global CDN, load balancing, and WAF protection |
| **Application Gateway** | Regional layer 7 load balancer with WAF capabilities |
| **Azure Firewall** | Network-level filtering and threat protection |
| **Virtual Network** | Isolated network with multiple subnets |
| **App Service** | Web application hosting with VNet integration |
| **Virtual Machine** | Ubuntu server for backend workloads |
| **Azure Bastion** | Secure RDP/SSH connectivity without public IPs |
| **Log Analytics** | Centralized logging and monitoring |

## 🚀 Quick Start

### Prerequisites

- Azure subscription
- Azure CLI installed ([Install Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli))
- Bash or PowerShell terminal

### Option 1: Deploy via Azure Portal (One-Click)

Click the button below to deploy directly from the Azure Portal:

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fcaiyunlin%2Fazure-end-to-end-network-lab%2Fmain%2Fazuredeploy.json)

1. Click the "Deploy to Azure" button
2. Fill in the required parameters:
   - **Subscription**: Select your Azure subscription
   - **Resource Group**: Create new or select existing
   - **Location**: Choose Azure region (e.g., East US)
   - **Environment Name**: Prefix for resource names (default: `netlab`)
   - **VM Admin Username**: Username for VM (default: `azureuser`)
   - **VM Admin Password**: Strong password for VM access
   - **App Service Plan SKU**: Service tier (default: `S1`)
   - **VM Size**: VM size (default: `Standard_B2s`)
3. Review and click "Create"
4. Wait 20-30 minutes for deployment to complete

### Option 2: Deploy via PowerShell (Windows)

```powershell
# Clone the repository
git clone https://github.com/caiyunlin/azure-end-to-end-network-lab.git
cd azure-end-to-end-network-lab

# Login to Azure
az login

# Run deployment script
$password = ConvertTo-SecureString "YourStrongPassword123!" -AsPlainText -Force
.\deploy.ps1 -Location "eastus" -EnvironmentName "mynetlab" -VmAdminPassword $password
```

### Option 3: Deploy via Bash (Linux/Mac)

```bash
# Clone the repository
git clone https://github.com/caiyunlin/azure-end-to-end-network-lab.git
cd azure-end-to-end-network-lab

# Make script executable
chmod +x deploy.sh

# Login to Azure
az login

# Run deployment script
./deploy.sh -l eastus -e mynetlab -p "YourStrongPassword123!"
```

### Option 4: Manual Deployment with Azure CLI

```bash
# Login to Azure
az login

# Create resource group
az group create --name rg-netlab --location eastus

# Deploy ARM template
az deployment group create \
  --name netlab-deployment \
  --resource-group rg-netlab \
  --template-file azuredeploy.json \
  --parameters location=eastus \
               environmentName=netlab \
               vmAdminPassword="YourStrongPassword123!"
```

## 📋 Deployment Parameters

| Parameter | Description | Default | Required |
|-----------|-------------|---------|----------|
| `location` | Azure region for deployment | Resource group location | No |
| `environmentName` | Prefix for all resource names | `netlab` | No |
| `vmAdminUsername` | VM administrator username | `azureuser` | No |
| `vmAdminPassword` | VM administrator password | - | **Yes** |
| `appServicePlanSku` | App Service Plan pricing tier | `S1` | No |
| `vmSize` | Virtual Machine size | `Standard_B2s` | No |

### Password Requirements
- Minimum 12 characters
- Contains uppercase, lowercase, number, and special character
- Example: `P@ssw0rd123!`

## 📊 Deployment Outputs

After successful deployment, you'll receive:

- **Front Door Endpoint**: Global entry point (e.g., `https://netlab-endpoint-xyz.azurefd.net`)
- **Application Gateway IP**: Regional load balancer public IP
- **Azure Firewall IP**: Firewall public IP address
- **App Service URL**: Web app hostname (e.g., `https://netlab-app-xyz.azurewebsites.net`)
- **VM Public IP**: Virtual machine public IP (for Bastion access)
- **Bastion Host**: Secure access gateway

## 🔒 Security Features

- **Azure Front Door**: DDoS protection, SSL/TLS termination, WAF rules
- **Application Gateway**: Layer 7 filtering, URL-based routing
- **Azure Firewall**: Network and application-level filtering
- **Network Security Groups**: Subnet-level access control
- **Azure Bastion**: Secure VM access without exposing RDP/SSH ports
- **VNet Integration**: App Service isolated within private network

## 🧪 Testing the Deployment

1. **Test Front Door Endpoint**:
   ```bash
   curl https://<frontdoor-endpoint>.azurefd.net
   ```

2. **Test Application Gateway**:
   ```bash
   curl http://<appgateway-public-ip>
   ```

3. **Access VM via Bastion**:
   - Navigate to Azure Portal → Virtual Machines → Select VM
   - Click "Connect" → "Bastion"
   - Enter credentials

4. **View Firewall Logs**:
   - Navigate to Azure Firewall → Logs
   - Query firewall activities and blocked traffic

## 🧹 Cleanup

To delete all resources and avoid charges:

```bash
# Delete resource group
az group delete --name rg-netlab --yes --no-wait
```

Or via PowerShell:

```powershell
Remove-AzResourceGroup -Name "rg-netlab" -Force
```

## 💰 Cost Estimation

Approximate monthly costs (East US region):
- Azure Front Door Standard: ~$35/month
- Application Gateway (Standard_v2): ~$140/month
- Azure Firewall: ~$840/month
- App Service (S1): ~$70/month
- Virtual Machine (B2s): ~$30/month
- Bastion (Basic): ~$140/month
- **Total**: ~$1,255/month

> **Note**: Actual costs may vary based on usage, data transfer, and region. Consider using lower-tier SKUs or stopping resources when not in use.

## 📚 Additional Resources

- [Azure Front Door Documentation](https://docs.microsoft.com/azure/frontdoor/)
- [Azure Firewall Documentation](https://docs.microsoft.com/azure/firewall/)
- [Application Gateway Documentation](https://docs.microsoft.com/azure/application-gateway/)
- [Azure Virtual Network Documentation](https://docs.microsoft.com/azure/virtual-network/)
- [App Service Documentation](https://docs.microsoft.com/azure/app-service/)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## ⚠️ Disclaimer

This lab is for educational and testing purposes. Review and adjust security settings before using in production environments.
