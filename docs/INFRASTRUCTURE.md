# Infrastructure as Code with Bicep

Deploy complete Odoo-MTA infrastructure on Azure in under 30 minutes.

---

## 📋 Quick Start

```bash
# 1. Login to Azure
az login

# 2. Create resource group
az group create --name rg-odoo-mta --location eastus

# 3. Deploy infrastructure
az deployment group create \
  --resource-group rg-odoo-mta \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters.json

# 4. Done! Access output endpoints
```

---

## Architecture

### Components Deployed

```
Azure Resource Group
├── Virtual Network (10.0.0.0/16)
│   ├── Subnet (10.0.1.0/24)
│   └── Network Security Group
├── Virtual Machines (×1 or more)
│   ├── OS: Ubuntu 20.04 LTS
│   ├── Docker pre-installed
│   ├── 2× Premium SSD (OS + Data)
│   └── Public IP + Network Interface
├── Storage Accounts
│   ├── Primary (Hot): Docker images
│   └── Backup (Cool): Database backups
└── Optional: Azure Database for PostgreSQL
```

### Network Security

**Inbound Rules**:
- SSH (22): From anywhere
- HTTP (80): From anywhere
- HTTPS (443): From anywhere
- Odoo (8069): From anywhere

**Outbound**: All allowed (for Docker pulls, GitHub, etc)

---

## Prerequisites

1. **Azure Subscription**
   - Active Azure account with billing enabled
   - Owner or Contributor role

2. **Local Tools**
   ```bash
   # Azure CLI
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

   # Bicep CLI (optional, Azure CLI includes it)
   az bicep install

   # jq (for parsing JSON)
   sudo apt-get install jq
   ```

3. **SSH Key Pair**
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_rsa
   cat ~/.ssh/azure_rsa.pub  # Copy this for parameter
   ```

---

## Parameters

### Configuration File: `parameters.json`

```json
{
  "projectName": "odoomta",          // 3-11 chars, lowercase
  "environment": "prod",              // dev, test, prod
  "location": "eastus",              // Azure region
  "vmCount": 1,                      // Number of VMs
  "vmSize": "Standard_D2s_v3",       // VM SKU
  "adminUsername": "azureuser",      // SSH user
  "adminPublicKey": "ssh-rsa AAA...", // Your SSH public key
  "dbPassword": "...",               // From Key Vault
  "odooPassword": "..."              // From Key Vault
}
```

### Customize Parameters

```bash
# Edit parameters
nano infrastructure/parameters.json

# Or use environment variables
export AZURE_LOCATION="westeurope"
export AZURE_VMSIZE="Standard_D4s_v3"  # For larger instances
export AZURE_PROJECT="yourodoo"
```

---

## Deployment Steps

### Step 1: Prepare SSH Key

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/azure_rsa -N ""

# Get public key
cat ~/.ssh/azure_rsa.pub
# Copy entire output, paste into parameters.json "adminPublicKey"
```

### Step 2: Setup Azure Key Vault (for Secrets)

```bash
# Create Key Vault
az keyvault create \
  --resource-group rg-odoo-mta \
  --name odoomta-kv

# Store secrets
az keyvault secret set \
  --vault-name odoomta-kv \
  --name odoo-db-password \
  --value 'YourSecurePassword123!'

az keyvault secret set \
  --vault-name odoomta-kv \
  --name odoo-admin-password \
  --value 'AdminPassword123!'

# Update parameters.json with Key Vault reference
```

### Step 3: Update Parameters File

```bash
# Copy template
cp infrastructure/parameters.example.json infrastructure/parameters.json

# Edit with your values
nano infrastructure/parameters.json
```

**Key fields to update**:
```json
{
  "projectName": { "value": "yourodoo" },
  "location": { "value": "eastus" },  // Change if needed
  "adminUsername": { "value": "ubuntu" },
  "adminPublicKey": { "value": "ssh-rsa AAAA..." },
  "dbPassword": { "reference": { "keyVault": {...} } },
  "odooPassword": { "reference": { "keyVault": {...} } }
}
```

### Step 4: Validate Template

```bash
# Check Bicep syntax
az bicep build --file infrastructure/main.bicep

# Validate deployment
az deployment group validate \
  --resource-group rg-odoo-mta \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters.json
```

### Step 5: Deploy

```bash
# Deploy (takes 5-10 minutes)
az deployment group create \
  --resource-group rg-odoo-mta \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters.json

# Wait for completion...
# ✓ Deployment complete
```

### Step 6: Get Output Information

```bash
# Show all outputs
az deployment group show \
  --resource-group rg-odoo-mta \
  --name main \
  --query properties.outputs

# Extract specific values
PUBLIC_IP=$(az deployment group show \
  --resource-group rg-odoo-mta \
  --name main \
  --query 'properties.outputs.publicIPs.value[0].ipAddress' \
  -o tsv)

echo "VM IP: $PUBLIC_IP"
```

---

## Post-Deployment Configuration

### Step 1: Connect to VM

```bash
# SSH into VM
ssh -i ~/.ssh/azure_rsa azureuser@<PUBLIC_IP>

# Verify Docker is running
docker ps
docker-compose --version
```

### Step 2: Clone Repository

```bash
cd /opt/odoo-mta

# Clone the project
sudo git clone https://github.com/resultrum/odoo-mta.git .

# Fix permissions
sudo chown -R azureuser:azureuser .

# Setup environment
cp .env.example .env
nano .env  # Edit with secrets
```

### Step 3: Start Odoo

```bash
# Pull images
docker-compose pull

# Start containers
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f odoo-mta-web

# Access at: http://<PUBLIC_IP>:8069
```

---

## Disaster Recovery: <30 Minute Redeploy

### Scenario: VM Corruption

**Redeploy in 4 steps**:

```bash
# 1. Delete old resource group (5 min)
az group delete --name rg-odoo-mta --yes

# 2. Create new resource group (1 min)
az group create --name rg-odoo-mta-v2 --location eastus

# 3. Deploy infrastructure (10 min)
az deployment group create \
  --resource-group rg-odoo-mta-v2 \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters.json

# 4. Restore data from backup (5-10 min)
# See Backup Recovery section below
```

**Total time: ~25-30 minutes**

### Backup Recovery

```bash
# List available backups
az storage blob list \
  --account-name odoomtaprodsa \
  --container-name backups \
  --output table

# Download latest backup
az storage blob download \
  --account-name odoomtaprodsa \
  --container-name backups \
  --name "database_2025-10-30_14-30-00.dump.gz" \
  --file /tmp/backup.dump.gz

# Restore to new VM
gunzip -c /tmp/backup.dump.gz | \
  docker exec -i odoo-mta-db psql -U odoo -d mta-prod
```

---

## Scaling

### Add More VMs

Update `parameters.json`:

```json
{
  "vmCount": { "value": 2 }  // Change from 1 to 2
}
```

Redeploy:
```bash
az deployment group create \
  --resource-group rg-odoo-mta \
  --template-file infrastructure/main.bicep \
  --parameters infrastructure/parameters.json
```

### Increase VM Size

```json
{
  "vmSize": { "value": "Standard_D4s_v3" }  // More CPU/RAM
}
```

Note: Requires VM restart.

### Add Managed Database

Uncomment PostgreSQL section in `main.bicep`:

```bicep
resource postgresqlServer 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  // ... configuration
}
```

---

## Monitoring & Maintenance

### Azure Portal

1. Go to Azure Portal (portal.azure.com)
2. Navigate to resource group: `rg-odoo-mta`
3. View:
   - VM status
   - Network configuration
   - Storage usage
   - Activity logs

### VM Monitoring

```bash
# SSH into VM
ssh -i ~/.ssh/azure_rsa azureuser@<PUBLIC_IP>

# Check resource usage
docker stats

# Check disk space
df -h

# Check backup storage
ls -lh /backups/odoo-mta/prod/
```

### Cost Analysis

```bash
# Estimate monthly cost
az cost management forecast create \
  --type "Usage" \
  --timeframe "MonthToDate" \
  --dataset-granularity "Daily"
```

**Typical costs** (Standard_D2s_v3):
- Compute: ~$100/month
- Storage: ~$20/month
- Backup: ~$5/month
- **Total**: ~$125/month

---

## Troubleshooting

### Deployment Failed

```bash
# Check error details
az deployment group show \
  --resource-group rg-odoo-mta \
  --name main \
  --query properties.error
```

### Cannot Connect to VM

```bash
# Check Network Security Group rules
az network nsg rule list \
  --resource-group rg-odoo-mta \
  --nsg-name odoomta-test-nsg

# Add SSH rule if missing
az network nsg rule create \
  --resource-group rg-odoo-mta \
  --nsg-name odoomta-test-nsg \
  --name AllowSSH \
  --priority 100 \
  --source-address-prefixes '*' \
  --destination-address-prefixes '*' \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 22
```

### Docker Not Starting

```bash
# SSH to VM
ssh -i ~/.ssh/azure_rsa azureuser@<PUBLIC_IP>

# Check Docker status
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Check logs
sudo journalctl -u docker -n 50
```

---

## Cleanup

```bash
# Delete resource group (removes everything)
az group delete --name rg-odoo-mta --yes

# Or keep infrastructure, delete only VMs
az vm delete --resource-group rg-odoo-mta --name odoomta-test-vm-0 --yes
```

---

## Advanced: Custom Bicep

### Modify Template

```bicep
// Edit infrastructure/main.bicep

// Change VM count
param vmCount int = 2

// Change storage tier
param storageSku string = 'Standard_GRS'  // Geo-redundant

// Add tags
param tags object = {
  environment: environment
  costCenter: 'engineering'
  team: 'devops'
}
```

### Add PostgreSQL Database

Uncomment in `main.bicep`:

```bicep
resource postgresqlServer 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: '${resourceNamePrefix}-postgres'
  location: location
  sku: {
    name: 'B_Gen5_2'
    tier: 'Basic'
    capacity: 2
    family: 'Gen5'
  }
  // ... rest of config
}
```

### Add Load Balancer

```bicep
resource loadBalancer 'Microsoft.Network/loadBalancers@2021-07-01' = {
  name: '${resourceNamePrefix}-lb'
  location: location
  // ... configuration
}
```

---

## References

- [Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure VM SKUs](https://docs.microsoft.com/en-us/azure/virtual-machines/sizes)
- [Azure Resource Manager Limits](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits)

---

**Version**: 1.0
**Last Updated**: 2025-10-30
**Maintained by**: DevOps Team
