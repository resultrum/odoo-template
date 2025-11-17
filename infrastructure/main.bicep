// Main infrastructure template for odoo-mta deployment on Azure
// Enables disaster recovery deployment in <30 minutes
// Usage: az deployment group create --resource-group rg-odoo-mta --template-file main.bicep --parameters parameters.json

@minLength(3)
@maxLength(11)
@description('Project name prefix for all resources')
param projectName string = 'odoomta'

@description('Environment name (dev, test, prod)')
param environment string = 'test'

@description('Azure region for deployment')
param location string = resourceGroup().location

@description('Number of VMs to deploy')
param vmCount int = 1

@description('VM SKU size')
param vmSize string = 'Standard_D2s_v3'

@description('Admin username for VMs')
param adminUsername string

@description('SSH public key for VM access')
param adminPublicKey string

@description('Database password')
@secure()
param dbPassword string

@description('Odoo admin password')
@secure()
param odooPassword string

@description('Tags for resource organization')
param tags object = {
  environment: environment
  project: 'odoo-mta'
  managedBy: 'bicep'
  createdDate: utcNow('yyyy-MM-dd')
}

// ============================================================================
// VARIABLES
// ============================================================================

var resourceNamePrefix = '${projectName}-${environment}'
var vnetName = '${resourceNamePrefix}-vnet'
var subnetName = '${resourceNamePrefix}-subnet'
var nsgName = '${resourceNamePrefix}-nsg'
var vmNamePrefix = '${resourceNamePrefix}-vm'
var nicNamePrefix = '${resourceNamePrefix}-nic'
var diskNamePrefix = '${resourceNamePrefix}-disk'
var pipNamePrefix = '${resourceNamePrefix}-pip'
var storageAccountName = '${projectName}${environment}sa'
var backupStorageName = '${projectName}${environment}backup'

// ============================================================================
// NETWORKING
// ============================================================================

resource vnet 'Microsoft.Network/virtualNetworks@2021-07-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-07-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowOdoo'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8069'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
    ]
  }
}

// ============================================================================
// PUBLIC IPS & NETWORK INTERFACES
// ============================================================================

resource publicIps 'Microsoft.Network/publicIPAddresses@2021-07-01' = [for i in range(0, vmCount): {
  name: '${pipNamePrefix}-${i}'
  location: location
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings: {
      domainNameLabel: '${resourceNamePrefix}-${i}-${uniqueString(resourceGroup().id)}'
    }
  }
}]

resource networkInterfaces 'Microsoft.Network/networkInterfaces@2021-07-01' = [for i in range(0, vmCount): {
  name: '${nicNamePrefix}-${i}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${subnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIps[i].id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}]

// ============================================================================
// STORAGE ACCOUNTS
// ============================================================================

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
  }
}

resource backupStorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: backupStorageName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Cool'
    minimumTlsVersion: 'TLS1_2'
  }
}

// Create blob containers
resource backupContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: '${backupStorageAccount.name}/default/backups'
  properties: {
    publicAccess: 'None'
  }
}

// ============================================================================
// VIRTUAL MACHINES
// ============================================================================

resource vmDisks 'Microsoft.Compute/disks@2021-07-01' = [for i in range(0, vmCount): {
  name: '${diskNamePrefix}-${i}'
  location: location
  tags: tags
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: 128
  }
}]

resource virtualMachines 'Microsoft.Compute/virtualMachines@2021-07-01' = [for i in range(0, vmCount): {
  name: '${vmNamePrefix}-${i}'
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${vmNamePrefix}-${i}'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        deleteOption: 'Delete'
      }
      dataDisks: [
        {
          lun: 0
          createOption: 'Attach'
          managedDisk: {
            id: vmDisks[i].id
          }
          deleteOption: 'Delete'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaces[i].id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}]

// ============================================================================
// CUSTOM SCRIPT EXTENSIONS (Install Docker & Odoo)
// ============================================================================

resource vmExtensions 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = [for i in range(0, vmCount): {
  parent: virtualMachines[i]
  name: 'DockerInstall'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: []
      commandToExecute: 'bash -c "${base64ToString(base64(initScript))}"'
    }
  }
}]

// Initialization script (base64 encoded for inline execution)
var initScript = '''#!/bin/bash
set -e

echo "Initializing Odoo server..."

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Create odoo user group
usermod -aG docker ${adminUsername}

# Create directories
mkdir -p /opt/odoo-mta/${environment}
mkdir -p /backups/odoo-mta/${environment}

# Mount data disk
if [ -b /dev/sdc ]; then
  mkfs.ext4 -F /dev/sdc
  echo '/dev/sdc /data ext4 defaults 0 0' >> /etc/fstab
  mkdir -p /data
  mount /data
  chmod 755 /data
fi

echo "Server initialization complete"
'''

// ============================================================================
// DATABASE (Optional: Azure Database for PostgreSQL)
// ============================================================================

// Uncomment to deploy managed PostgreSQL database
/*
resource postgresqlServer 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: '${resourceNamePrefix}-postgres'
  location: location
  sku: {
    name: 'B_Gen5_2'
    tier: 'Basic'
    capacity: 2
    family: 'Gen5'
  }
  properties: {
    createMode: 'Default'
    version: '11'
    administratorLogin: 'pgadmin'
    administratorLoginPassword: dbPassword
    sslEnforcement: 'ENABLED'
    minimalTlsVersion: 'TLS1_2'
    storageProfile: {
      storageMB: 51200
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
  }
}
*/

// ============================================================================
// OUTPUTS
// ============================================================================

@description('Public IP addresses of deployed VMs')
output publicIPs array = [for i in range(0, vmCount): {
  vmName: virtualMachines[i].name
  ipAddress: publicIps[i].properties.ipAddress
  fqdn: publicIps[i].properties.dnsSettings.fqdn
}]

@description('Storage account connection information')
output storageInfo object = {
  accountName: storageAccount.name
  backupContainer: '${backupStorageAccount.name}/backups'
}

@description('Virtual machine IDs')
output vmIds array = [for i in range(0, vmCount): {
  vmName: virtualMachines[i].name
  vmId: virtualMachines[i].id
}]

@description('Resource group information')
output resourceInfo object = {
  resourceGroup: resourceGroup().name
  location: location
  environment: environment
}

@description('Commands to access VMs')
output accessCommands array = [for i in range(0, vmCount): {
  vmName: virtualMachines[i].name
  sshCommand: 'ssh ${adminUsername}@${publicIps[i].properties.ipAddress}'
}]
