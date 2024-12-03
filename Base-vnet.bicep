param VNETname string
param VNETPrefix string

resource VNETname_resource 'Microsoft.Network/virtualNetworks@2016-03-30' = {
  name: VNETname
  location: resourceGroup().location
  tags: {
    displayName: 'VNET'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        VNETPrefix
      ]
    }
    subnets: []
  }
  dependsOn: []
}
