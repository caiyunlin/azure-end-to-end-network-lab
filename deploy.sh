#!/bin/bash
###############################################################################
# Azure End-to-End Networking Lab Deployment Script (Bash)
# 
# This script deploys an end-to-end Azure networking lab featuring Front Door,
# Firewall, Application Gateway, VNet, App Service, and VM using ARM templates.
###############################################################################

set -e

# Default values
LOCATION="eastus"
ENVIRONMENT_NAME="netlab"
RESOURCE_GROUP_NAME=""
APP_SERVICE_PLAN_SKU="S1"
VM_SIZE="Standard_D2s_v3"
VM_ADMIN_PASSWORD=""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT_NAME="$2"
            shift 2
            ;;
        -g|--resource-group)
            RESOURCE_GROUP_NAME="$2"
            shift 2
            ;;
        -p|--password)
            VM_ADMIN_PASSWORD="$2"
            shift 2
            ;;
        -s|--app-sku)
            APP_SERVICE_PLAN_SKU="$2"
            shift 2
            ;;
        -v|--vm-size)
            VM_SIZE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: ./deploy.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -l, --location          Azure region (default: eastus)"
            echo "  -e, --environment       Environment name prefix (default: netlab)"
            echo "  -g, --resource-group    Resource group name (default: rg-{environment})"
            echo "  -p, --password          VM admin password (required)"
            echo "  -s, --app-sku           App Service Plan SKU (default: S1)"
            echo "  -v, --vm-size           VM size (default: Standard_D2s_v3)"
            echo "  -h, --help              Show this help message"
            echo ""
            echo "Example:"
            echo "  ./deploy.sh -l eastus -e mynetlab -p 'P@ssw0rd123!'"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$VM_ADMIN_PASSWORD" ]; then
    echo -e "${RED}Error: VM admin password is required${NC}"
    echo "Use -p or --password to provide the password"
    exit 1
fi

# Generate resource group name if not provided
if [ -z "$RESOURCE_GROUP_NAME" ]; then
    RESOURCE_GROUP_NAME="rg-$ENVIRONMENT_NAME"
fi

echo -e "${CYAN}========================================"
echo "Azure End-to-End Networking Lab Deployment"
echo -e "========================================${NC}"
echo ""

# Check if Azure CLI is installed
echo -e "${YELLOW}Checking Azure CLI installation...${NC}"
if ! command -v az &> /dev/null; then
    echo -e "${RED}✗ Azure CLI is not installed${NC}"
    echo "Please install it from https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

AZ_VERSION=$(az version --query '\"azure-cli\"' -o tsv)
echo -e "${GREEN}✓ Azure CLI version $AZ_VERSION is installed${NC}"

# Check if logged in to Azure
echo -e "${YELLOW}Checking Azure login status...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${RED}✗ Not logged in to Azure. Running 'az login'...${NC}"
    az login
fi

ACCOUNT_NAME=$(az account show --query name -o tsv)
ACCOUNT_ID=$(az account show --query id -o tsv)
USER_NAME=$(az account show --query user.name -o tsv)
echo -e "${GREEN}✓ Logged in as $USER_NAME${NC}"
echo -e "${GREEN}✓ Using subscription: $ACCOUNT_NAME ($ACCOUNT_ID)${NC}"
echo ""

# Create resource group
echo -e "${YELLOW}Creating resource group '$RESOURCE_GROUP_NAME' in '$LOCATION'...${NC}"
az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" --output table

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to create resource group${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Resource group created successfully${NC}"
echo ""

# Prepare deployment
TIMESTAMP=$(date +%Y%m%d%H%M%S)
DEPLOYMENT_NAME="netlab-deployment-$TIMESTAMP"

echo -e "${YELLOW}Starting ARM template deployment...${NC}"
echo -e "${CYAN}Deployment name: $DEPLOYMENT_NAME${NC}"
echo -e "${CYAN}This may take 20-30 minutes...${NC}"
echo ""

# Deploy ARM template
az deployment group create \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file "azuredeploy.json" \
    --parameters location="$LOCATION" \
                 environmentName="$ENVIRONMENT_NAME" \
                 vmAdminPassword="$VM_ADMIN_PASSWORD" \
                 appServicePlanSku="$APP_SERVICE_PLAN_SKU" \
                 vmSize="$VM_SIZE" \
    --output table

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Deployment failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}========================================"
echo "Deployment completed successfully!"
echo -e "========================================${NC}"
echo ""

# Get deployment outputs
echo -e "${YELLOW}Retrieving deployment outputs...${NC}"
OUTPUTS=$(az deployment group show \
    --name "$DEPLOYMENT_NAME" \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query properties.outputs \
    --output json)

FRONT_DOOR_ENDPOINT=$(echo "$OUTPUTS" | jq -r '.frontDoorEndpoint.value')
APP_GATEWAY_IP=$(echo "$OUTPUTS" | jq -r '.appGatewayPublicIP.value')
FIREWALL_IP=$(echo "$OUTPUTS" | jq -r '.firewallPublicIP.value')
APP_SERVICE_HOSTNAME=$(echo "$OUTPUTS" | jq -r '.appServiceHostName.value')
VM_PUBLIC_IP=$(echo "$OUTPUTS" | jq -r '.vmPublicIP.value')
BASTION_HOSTNAME=$(echo "$OUTPUTS" | jq -r '.bastionHostName.value')

echo ""
echo -e "${CYAN}========================================"
echo "Deployment Outputs"
echo -e "========================================${NC}"
echo "Front Door Endpoint:       https://$FRONT_DOOR_ENDPOINT"
echo "App Gateway Public IP:     $APP_GATEWAY_IP"
echo "Firewall Public IP:        $FIREWALL_IP"
echo "App Service Hostname:      https://$APP_SERVICE_HOSTNAME"
echo "VM Public IP:              $VM_PUBLIC_IP"
echo "Bastion Host:              $BASTION_HOSTNAME"
echo ""
echo "Resource Group:            $RESOURCE_GROUP_NAME"
echo "Location:                  $LOCATION"
echo -e "${CYAN}========================================${NC}"
echo ""
echo -e "${YELLOW}Access your resources:${NC}"
echo "  • Front Door: https://$FRONT_DOOR_ENDPOINT"
echo "  • Azure Portal: https://portal.azure.com/#resource/subscriptions/$ACCOUNT_ID/resourceGroups/$RESOURCE_GROUP_NAME"
echo ""
