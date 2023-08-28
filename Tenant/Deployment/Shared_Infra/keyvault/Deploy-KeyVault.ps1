# Deploying bicep file
#. '.\Variables.ps1'
#Azure cli
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string] $resourceGroup,

    [Parameter(Mandatory)]
    [string] $subscription
)
az login --use-device-code
az account set -s $subscription

$rsgExists = az group exists --name $resourceGroup
if ( 'false' -eq $rsgExists ) {
  az group create --name $resourceGroup --location $location
  Write-Host "New resource group $($resourceGroup) is created"
}else {
  Write-Host "Resource group $($resourceGroup) already exists"
}

az deployment group create --resource-group $resourceGroup  --template-file .\keyVault.bicep

