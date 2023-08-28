@description('Specifies the Azure location where the key vault should be created.')
param share_kv_name string

@description('Specify environment you are deploying')
@allowed([
  'DEV'
  'TEST'
  'PROD'
])
param environment string

@description('Specifies the Azure location where the key vault should be created.')
param location string = resourceGroup().location

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests')
param tenantId string = subscription().tenantId

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param objectId string 

@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
param keysPermissions array = [
  'Get'
  'List'
]

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
param secretsPermissions array = [
  'Get'
  'List'
]

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
])
param skuName string = 'standard'
param utcShort string = utcNow('d')

resource share_kv_name_resource 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: '${toLower(environment)}-${share_kv_name}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: tenantId
    accessPolicies: [ 
      {
        tenantId: tenantId
        objectId: objectId
        permissions: {
          keys: keysPermissions
          secrets:secretsPermissions
          certificates: [
            'Get'
            'List'
            'Update'
            'Create'
            'Import'
            'Delete'
            'Recover'
            'Backup'
            'Restore'
            'ManageContacts'
            'ManageIssuers'
            'GetIssuers'
            'ListIssuers'
            'SetIssuers'
            'DeleteIssuers'
          ]
        }
      }
    ]
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: false
  }
  tags: {
    Environment:environment
    LastDeployed: utcShort
  }
}


