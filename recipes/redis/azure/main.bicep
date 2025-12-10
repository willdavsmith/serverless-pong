@description('Radius-provided object containing information about the resouce calling the Recipe')
param context object

@description('The geo-location where the resource lives.')
param location string = resourceGroup().location

@description('The size of the Redis cache to deploy. Valid values: for C (Basic/Standard) family (0, 1, 2, 3, 4, 5, 6), for P (Premium) family (1, 2, 3, 4).')
@minValue(0)
@maxValue(6)
param skuCapacity int = 3

@description('The SKU family to use. Valid values: (C, P). (C = Basic/Standard, P = Premium).')
@allowed([
  'C'
  'P'
])
param skuFamily string = 'P'

@description('The type of Redis cache to deploy. Valid values: (Basic, Standard, Premium)')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param skuName string = 'Premium'

@description('The user-defined tags that will be applied to the resource. Default is null')
param tags object = {}

@description('The Radius specific tags that will be applied to the resource')
var radiusTags = {
  'radapp.io-environment': context.environment.id
  'radapp.io-application': context.application == null ? '' : context.application.id
  'radapp.io-resource': context.resource.id
}

resource azureCache 'Microsoft.Cache/redis@2022-06-01' = {
  name: 'cache-${uniqueString(context.resource.id, resourceGroup().id)}'
  location: location
  tags: union(tags, radiusTags)
  properties: {
    sku: {
      capacity: skuCapacity
      family: skuFamily
      name: skuName
    }
  }
}

output result object = {
  values: {
    host: azureCache.properties.hostName
    port: azureCache.properties.sslPort
    username: ''
    tls: true
  }
  secrets: {
    #disable-next-line outputs-should-not-contain-secrets
    password: azureCache.listKeys().primaryKey
  }
}
