targetScope = 'subscription'

@description('Name of Resource Group')
param resourceGroupName string = 'devbox-rg'
@description('Azure region')
param location string = 'swedencentral'
@description('VM Admin username')
param adminUsername string
@description('VM Admin password')
@secure()
param adminPassword string
@description('VM size')
param vmSize string = 'Standard_DS2_v2'
@description('Powershell setup script location')
param scriptUri string
@description('My public ip address (ex. 192.168.0.1/32)')
param myPublicIp string

resource rg 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
}

module vm 'vm.bicep' = {
  name: 'vmDeployment'
  scope: resourceGroup(rg.name)
  params: {
    location: location
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSize
    scriptUri: scriptUri
    myPublicIp: myPublicIp
  }
}
