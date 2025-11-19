#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys the Azure End-to-End Networking Lab
.DESCRIPTION
    This script deploys an end-to-end Azure networking lab featuring Front Door, 
    Firewall, Application Gateway, VNet, App Service, and VM using ARM templates.
.PARAMETER Location
    Azure region where resources will be deployed (default: eastus)
.PARAMETER EnvironmentName
    Environment name prefix for all resources (default: netlab)
.PARAMETER ResourceGroupName
    Name of the resource group (default: rg-{environmentName})
.PARAMETER VmAdminPassword
    Admin password for the Virtual Machine (must meet complexity requirements)
.EXAMPLE
    .\deploy.ps1 -Location "eastus" -EnvironmentName "mynetlab" -VmAdminPassword "P@ssw0rd123!"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Location = "eastus",
    
    [Parameter(Mandatory=$false)]
    [string]$EnvironmentName = "netlab",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "",
    
    [Parameter(Mandatory=$true)]
    [string]$VmAdminPassword,

    [Parameter(Mandatory=$false)]
    [string]$AppServicePlanSku = "S1",

    [Parameter(Mandatory=$false)]
    [string]$VmSize = "Standard_D2s_v3"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Generate resource group name if not provided
if ([string]::IsNullOrEmpty($ResourceGroupName)) {
    $ResourceGroupName = "rg-$EnvironmentName"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Azure End-to-End Networking Lab Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Azure CLI is installed
Write-Host "Checking Azure CLI installation..." -ForegroundColor Yellow
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "✓ Azure CLI version $($azVersion.'azure-cli') is installed" -ForegroundColor Green
} catch {
    Write-Host "✗ Azure CLI is not installed. Please install it from https://docs.microsoft.com/cli/azure/install-azure-cli" -ForegroundColor Red
    exit 1
}

# Check if logged in to Azure
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if ($null -eq $account) {
    Write-Host "✗ Not logged in to Azure. Running 'az login'..." -ForegroundColor Red
    az login
    $account = az account show | ConvertFrom-Json
}
Write-Host "✓ Logged in as $($account.user.name)" -ForegroundColor Green
Write-Host "✓ Using subscription: $($account.name) ($($account.id))" -ForegroundColor Green
Write-Host ""

# Create resource group
Write-Host "Creating resource group '$ResourceGroupName' in '$Location'..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location --output table
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to create resource group" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Resource group created successfully" -ForegroundColor Green
Write-Host ""

# Validate password meets Azure requirements
if ($VmAdminPassword.Length -lt 12) {
    Write-Host "✗ Password must be at least 12 characters long" -ForegroundColor Red
    exit 1
}

# Prepare deployment parameters
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$deploymentName = "netlab-deployment-$timestamp"

Write-Host "Starting ARM template deployment..." -ForegroundColor Yellow
Write-Host "Deployment name: $deploymentName" -ForegroundColor Cyan
Write-Host "This may take 20-30 minutes..." -ForegroundColor Cyan
Write-Host ""

# Validate ARM template first
Write-Host "Validating ARM template..." -ForegroundColor Yellow
$validation = az deployment group validate `
    --resource-group $ResourceGroupName `
    --template-file "azuredeploy.json" `
    --parameters location=$Location `
                 environmentName=$EnvironmentName `
                 vmAdminPassword=$VmAdminPassword `
                 appServicePlanSku=$AppServicePlanSku `
                 vmSize=$VmSize `
    --output json 2>&1 | ConvertFrom-Json

if ($LASTEXITCODE -ne 0 -or $validation.error) {
    Write-Host "✗ Template validation failed:" -ForegroundColor Red
    Write-Host ($validation | ConvertTo-Json -Depth 10) -ForegroundColor Red
    exit 1
}
Write-Host "✓ Template validation successful" -ForegroundColor Green
Write-Host ""

# Deploy ARM template
az deployment group create `
    --name $deploymentName `
    --resource-group $ResourceGroupName `
    --template-file "azuredeploy.json" `
    --parameters location=$Location `
                 environmentName=$EnvironmentName `
                 vmAdminPassword=$VmAdminPassword `
                 appServicePlanSku=$AppServicePlanSku `
                 vmSize=$VmSize `
    --verbose

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Deployment failed. Checking deployment status..." -ForegroundColor Red
    
    # Try to get deployment details
    $deploymentInfo = az deployment group show `
        --name $deploymentName `
        --resource-group $ResourceGroupName `
        --output json 2>&1
    
    if ($deploymentInfo) {
        Write-Host "Deployment details:" -ForegroundColor Yellow
        Write-Host $deploymentInfo -ForegroundColor Yellow
    }
    
    # Get deployment operations for more details
    Write-Host "`nChecking deployment operations..." -ForegroundColor Yellow
    az deployment operation group list `
        --resource-group $ResourceGroupName `
        --name $deploymentName `
        --output table 2>&1
    
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Get deployment outputs
Write-Host "Retrieving deployment outputs..." -ForegroundColor Yellow
$outputs = az deployment group show `
    --name $deploymentName `
    --resource-group $ResourceGroupName `
    --query properties.outputs `
    --output json | ConvertFrom-Json

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Outputs" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Front Door Endpoint:       https://$($outputs.frontDoorEndpoint.value)" -ForegroundColor White
Write-Host "App Gateway Public IP:     $($outputs.appGatewayPublicIP.value)" -ForegroundColor White
Write-Host "Firewall Public IP:        $($outputs.firewallPublicIP.value)" -ForegroundColor White
Write-Host "App Service Hostname:      https://$($outputs.appServiceHostName.value)" -ForegroundColor White
Write-Host "VM Public IP:              $($outputs.vmPublicIP.value)" -ForegroundColor White
Write-Host "Bastion Host:              $($outputs.bastionHostName.value)" -ForegroundColor White
Write-Host ""
Write-Host "Resource Group:            $ResourceGroupName" -ForegroundColor White
Write-Host "Location:                  $Location" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access your resources:" -ForegroundColor Yellow
Write-Host "  • Front Door: https://$($outputs.frontDoorEndpoint.value)" -ForegroundColor White
Write-Host "  • Azure Portal: https://portal.azure.com/#resource/subscriptions/$($account.id)/resourceGroups/$ResourceGroupName" -ForegroundColor White
Write-Host ""
