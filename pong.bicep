extension radius
extension radiusCompute

@description('The ID of your Radius Environment. Set automatically by the rad CLI.')
param environment string

param image string

param name string

resource functionapp 'Applications.Core/applications@2023-10-01-preview' = {
  name: '${name}-app'
  properties: {
    environment: environment
  }
}

resource function 'Radius.Compute/functions@2025-12-08-preview' = {
  name: '${name}-func'
  properties: {
    environment: environment
    application: functionapp.id
    image: image
    connections: {
      redis: {
        source: redis.id
      }
    }
  }
}

resource redis 'Applications.Datastores/redisCaches@2023-10-01-preview' = {
  name: '${name}-redis'
  properties: {
    application: functionapp.id
    environment: environment
  }
}
