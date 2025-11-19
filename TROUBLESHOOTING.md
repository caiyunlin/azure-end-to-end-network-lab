# Troubleshooting Guide

## Common Deployment Issues

### 1. Deployment Fails with "Resource Already Exists"

**Symptom:** Deployment error stating a resource name is already taken.

**Cause:** Resource names must be globally unique (App Service, Front Door, Storage).

**Solution:**
```bash
# Use a different environment name
./deploy.sh -e mynetlab2 -p "YourPassword123!"

# Or add a unique suffix manually in parameters
```

---

### 2. VM Password Doesn't Meet Complexity Requirements

**Symptom:** Deployment fails with "Password validation failed"

**Requirements:**
- Minimum 12 characters
- At least 1 uppercase letter
- At least 1 lowercase letter
- At least 1 number
- At least 1 special character

**Solution:**
```bash
# Use a strong password like:
./deploy.sh -p "MyStr0ng!P@ssword2024"
```

---

### 3. Deployment Takes Too Long (>30 minutes)

**Symptom:** Deployment seems stuck or very slow.

**Causes:**
- Azure Firewall takes 10-15 minutes to deploy
- Application Gateway takes 5-10 minutes
- Bastion takes 5-10 minutes

**Solution:**
- Be patient; deployment typically takes 20-30 minutes
- Check deployment progress in Azure Portal:
  ```bash
  # Get deployment status
  az deployment group show \
    --name <deployment-name> \
    --resource-group <rg-name> \
    --query properties.provisioningState
  ```

---

### 4. "Quota Exceeded" Error

**Symptom:** Error message about exceeding subscription quota.

**Common quotas:**
- vCPUs per region
- Public IP addresses
- Load balancers

**Solution:**
```bash
# Check current quota usage
az vm list-usage --location eastus --output table

# Request quota increase
# Navigate to: Azure Portal → Subscriptions → Usage + quotas
# Or use support request
```

**Alternative:** Deploy to a different region or use smaller VM sizes.

---

### 5. Application Gateway Fails to Start

**Symptom:** Application Gateway stuck in "Updating" state.

**Causes:**
- Subnet too small
- NSG blocking required ports
- Backend pool misconfiguration

**Solution:**
```bash
# Check Application Gateway status
az network application-gateway show \
  --resource-group <rg-name> \
  --name <appgw-name> \
  --query provisioningState

# View backend health
az network application-gateway show-backend-health \
  --resource-group <rg-name> \
  --name <appgw-name>
```

---

## Connectivity Issues

### 6. Cannot Access Front Door Endpoint

**Symptom:** Front Door URL returns 404 or timeout.

**Troubleshooting steps:**

1. **Check Front Door status:**
   ```bash
   az afd endpoint show \
     --resource-group <rg-name> \
     --profile-name <fd-name> \
     --endpoint-name <endpoint-name>
   ```

2. **Verify origin health:**
   - Navigate to Azure Portal → Front Door → Origin groups
   - Check origin health status

3. **Test Application Gateway directly:**
   ```bash
   # Get App Gateway public IP
   az network public-ip show \
     --resource-group <rg-name> \
     --name <appgw-pip-name> \
     --query ipAddress -o tsv
   
   # Test connectivity
   curl http://<app-gateway-ip>
   ```

4. **Check NSG rules:**
   - Ensure HTTP (80) and HTTPS (443) are allowed

---

### 7. Cannot Connect to VM via Bastion

**Symptom:** Bastion connection fails or times out.

**Solutions:**

1. **Verify Bastion deployment:**
   ```bash
   az network bastion show \
     --resource-group <rg-name> \
     --name <bastion-name>
   ```

2. **Check VM is running:**
   ```bash
   az vm get-instance-view \
     --resource-group <rg-name> \
     --name <vm-name> \
     --query instanceView.statuses[1].displayStatus
   ```

3. **Start VM if stopped:**
   ```bash
   az vm start \
     --resource-group <rg-name> \
     --name <vm-name>
   ```

4. **Verify NSG allows Bastion:**
   - Check VMSubnet NSG for port 22 (SSH) or 3389 (RDP)

---

### 8. App Service Returns 503 Error

**Symptom:** App Service URL shows "Service Unavailable"

**Causes:**
- App Service not started
- VNet integration issue
- Application error

**Solutions:**

1. **Check App Service status:**
   ```bash
   az webapp show \
     --resource-group <rg-name> \
     --name <app-name> \
     --query state
   ```

2. **Start App Service:**
   ```bash
   az webapp start \
     --resource-group <rg-name> \
     --name <app-name>
   ```

3. **Deploy a test application:**
   ```bash
   # Deploy simple HTML page
   echo "<html><body><h1>Test App</h1></body></html>" > index.html
   
   az webapp deployment source config-zip \
     --resource-group <rg-name> \
     --name <app-name> \
     --src index.html.zip
   ```

4. **Check application logs:**
   ```bash
   az webapp log tail \
     --resource-group <rg-name> \
     --name <app-name>
   ```

---

## Firewall Issues

### 9. Azure Firewall Blocking Traffic

**Symptom:** Outbound connections from VM fail.

**Troubleshooting:**

1. **Check firewall logs:**
   ```bash
   # Query Log Analytics
   az monitor log-analytics query \
     --workspace <workspace-id> \
     --analytics-query "AzureDiagnostics | where Category == 'AzureFirewallApplicationRule' or Category == 'AzureFirewallNetworkRule' | where msg_s contains 'Deny' | take 20"
   ```

2. **Verify firewall rules:**
   ```bash
   az network firewall show \
     --resource-group <rg-name> \
     --name <firewall-name>
   ```

3. **Add application rule (if needed):**
   ```bash
   az network firewall application-rule create \
     --resource-group <rg-name> \
     --firewall-name <firewall-name> \
     --collection-name AllowWeb \
     --name Allow-Example \
     --protocols Http=80 Https=443 \
     --source-addresses "*" \
     --target-fqdns "example.com"
   ```

---

### 10. NSG Blocking Traffic

**Symptom:** Cannot access resources despite correct configuration.

**Solutions:**

1. **View effective NSG rules:**
   ```bash
   az network nic show-effective-nsg \
     --resource-group <rg-name> \
     --name <nic-name>
   ```

2. **Add NSG rule:**
   ```bash
   az network nsg rule create \
     --resource-group <rg-name> \
     --nsg-name <nsg-name> \
     --name Allow-Custom-Port \
     --priority 200 \
     --source-address-prefixes "*" \
     --destination-port-ranges 8080 \
     --direction Inbound \
     --access Allow \
     --protocol Tcp
   ```

---

## Performance Issues

### 11. High Latency or Slow Response

**Causes:**
- Firewall inspection overhead
- Application Gateway health probe failures
- Backend application performance

**Solutions:**

1. **Check Application Gateway metrics:**
   - Navigate to Azure Portal → Application Gateway → Metrics
   - Monitor: Backend response time, Failed requests

2. **Verify backend health:**
   ```bash
   az network application-gateway show-backend-health \
     --resource-group <rg-name> \
     --name <appgw-name>
   ```

3. **Check firewall metrics:**
   - Navigate to Azure Portal → Azure Firewall → Metrics
   - Monitor: Throughput, SNAT port utilization

4. **Scale resources:**
   ```bash
   # Scale App Service
   az appservice plan update \
     --resource-group <rg-name> \
     --name <plan-name> \
     --sku P1v2
   
   # Increase App Gateway capacity
   az network application-gateway update \
     --resource-group <rg-name> \
     --name <appgw-name> \
     --capacity 3
   ```

---

## Monitoring & Diagnostics

### 12. Enable Diagnostic Logging

**For Application Gateway:**
```bash
az monitor diagnostic-settings create \
  --resource <appgw-resource-id> \
  --name appgw-diagnostics \
  --workspace <log-analytics-workspace-id> \
  --logs '[{"category": "ApplicationGatewayAccessLog", "enabled": true}, {"category": "ApplicationGatewayPerformanceLog", "enabled": true}, {"category": "ApplicationGatewayFirewallLog", "enabled": true}]'
```

**For Azure Firewall:**
```bash
az monitor diagnostic-settings create \
  --resource <firewall-resource-id> \
  --name firewall-diagnostics \
  --workspace <log-analytics-workspace-id> \
  --logs '[{"category": "AzureFirewallApplicationRule", "enabled": true}, {"category": "AzureFirewallNetworkRule", "enabled": true}]'
```

---

### 13. Common Log Queries

**Firewall denied traffic:**
```kql
AzureDiagnostics
| where Category in ("AzureFirewallApplicationRule", "AzureFirewallNetworkRule")
| where msg_s contains "Deny"
| project TimeGenerated, Category, msg_s
| order by TimeGenerated desc
```

**Application Gateway failed requests:**
```kql
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where httpStatus_d >= 400
| summarize count() by httpStatus_d, requestUri_s
| order by count_ desc
```

**NSG flow logs:**
```kql
AzureNetworkAnalytics_CL
| where SubType_s == "FlowLog"
| where FlowStatus_s == "D" // Denied
| project TimeGenerated, SrcIP_s, DestIP_s, L7Protocol_s, DestPort_d
```

---

## Getting Help

### Azure Support Resources

1. **Azure Documentation:**
   - [Azure Front Door](https://docs.microsoft.com/azure/frontdoor/)
   - [Azure Firewall](https://docs.microsoft.com/azure/firewall/)
   - [Application Gateway](https://docs.microsoft.com/azure/application-gateway/)

2. **Azure Support:**
   - Portal: Help + Support → New Support Request
   - CLI: `az support --help`

3. **Community Forums:**
   - [Microsoft Q&A](https://docs.microsoft.com/answers/)
   - [Stack Overflow - Azure](https://stackoverflow.com/questions/tagged/azure)
   - [Azure Reddit](https://reddit.com/r/AZURE/)

4. **Check Service Health:**
   ```bash
   az rest --method get \
     --uri "https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.ResourceHealth/availabilityStatuses?api-version=2020-05-01"
   ```

---

## Quick Diagnostic Commands

```bash
# Check all resource states in resource group
az resource list \
  --resource-group <rg-name> \
  --query "[].{Name:name, Type:type, State:properties.provisioningState}" \
  --output table

# Get all public IPs
az network public-ip list \
  --resource-group <rg-name> \
  --query "[].{Name:name, IP:ipAddress}" \
  --output table

# Check VM status
az vm list \
  --resource-group <rg-name> \
  --show-details \
  --query "[].{Name:name, PowerState:powerState}" \
  --output table

# View deployment history
az deployment group list \
  --resource-group <rg-name> \
  --query "[].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp}" \
  --output table
```
