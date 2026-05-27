param location string = 'italynorth'
param environmentName string = 'cae-cloudnative-env'
param appName string = 'ca-cloudnative-api'
param acrName string = 'acrcloudnative${uniqueString(resourceGroup().id)}'

// RESURS 1: Log Analytics Workspace (Kommenterad bort då befintlig miljö används)
/*
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'law-student-logs'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018' // Standard för Azure for Students
    }
    retentionInDays: 30
  }
}
*/

// RESURS 2: Azure Container Apps Environment (Kommenterad bort då befintlig miljö används)
/*
resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: environmentName
  location: location
  properties: {
    zoneRedundant: false // Mycket viktigt för Azure for Students
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}
*/

// RESURS 3: Azure Container Registry (ACR) (Kommenterad bort då befintligt ACR används)
/*
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic' // Mycket viktigt för Azure for Students!
  }
  properties: {
    adminUserEnabled: true // Gör det enkelt för oss att logga in tillfälligt.
  }
}
*/

// Hämta befintliga resurser
resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: 'env-joco-inventory'
  scope: resourceGroup('rg-joco-dev')
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: 'acrjocoinventory'
  scope: resourceGroup('rg-joco-dev')
}

// RESURS 4: Azure Container App (.NET 9 API)
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: appName
  location: location
  // Vi sätter på SystemAssigned Managed Identity
  // För att appen ska kunna hämta secrets från Key Vault utan lösenord senare.
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        // Target port 8080.
        // Eftersom vi kör .NET 9 Rootless Containers lyssnar de automatiskt på 8080 (icke-privilegierad port), inte 80.
        targetPort: 8080
        allowInsecure: false // Tvingar HTTPS 
        // CORS POLICYN
        corsPolicy: {
          allowedOrigins: [
            '*'
          ]
          allowedMethods: [
            'GET'
            'POST'
          ]
          allowedHeaders: [
            '*'
          ]
        }
      }
    }
    template: {
      containers: [
        {
          name: 'inventory-api'
          // Vi startar med en tillfällig standard-image. Vår GitHub Actions pipeline kommer byta ut denna senare.
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.25') // Minsta möjliga för att spara student-krediter
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1 // Undviker kallstart under utveckling (kostar väldigt lite)
        maxReplicas: 3
      }
    }
  }
}
