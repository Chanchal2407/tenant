#!/bin/bash

# Function app and storage account names must be unique.
# Specify resource group where you want to create function app
#myResourceGroup="Share-Dev"
# Product
productstorageName=syncproductiontaxonomy
productfunctionAppName=inorigoproducttaxonomySync
region=westeurope

# Industries
industrystorageName=syncpndustrytaxonomy
industryfunctionAppName=inorigoindustrytaxonomySync
region=westeurope

# Document
documentstorageName=syncdocumenttaxonomy
documentfunctionAppName=inorigodocumenttaxonomySync
region=westeurope

# Service
servicestorageName=syncservicetaxonomy
servicefunctionAppName=inorigoservicetaxonomySync
region=westeurope


# Create an Azure storage account in the resource group.
az storage account create  --name $productstorageName --location $region  --resource-group "Share-Dev" --sku Standard_LRS
az storage account create  --name $industrystorageName --location $region  --resource-group "Share-Dev" --sku Standard_LRS
az storage account create  --name $documentstorageName --location $region  --resource-group "Share-Dev" --sku Standard_LRS
az storage account create  --name $servicestorageName --location $region  --resource-group "Share-Dev" --sku Standard_LRS

# Create a serverless function app in the resource group.
az functionapp create --name $productfunctionAppName --storage-account $productstorageName --consumption-plan-location $region --resource-group "Share-Dev" --functions-version 2
az functionapp create --name $industryfunctionAppName --storage-account $industrystorageName --consumption-plan-location $region --resource-group "Share-Dev" --functions-version 2
az functionapp create --name $documentfunctionAppName --storage-account $documentstorageName --consumption-plan-location $region --resource-group "Share-Dev" --functions-version 2
az functionapp create --name $servicestorageName --storage-account $servicefunctionAppName --consumption-plan-location $region --resource-group "Share-Dev" --functions-version 2

# Add Functions Configuration settings
# Product
az functionapp config appsettings set --name $productfunctionAppName  --resource-group "Share-Dev" --settings "appID=test"
az functionapp config appsettings set --name $productfunctionAppName  --resource-group "Share-Dev" --settings "appSecret=test"
az functionapp config appsettings set --name $productfunctionAppName  --resource-group "Share-Dev" --settings "AdminPortalSiteUrl=test"
az functionapp config appsettings set --name $productfunctionAppName  --resource-group "Share-Dev" --settings "emailRecipientsTo=test"
az functionapp config appsettings set --name $productfunctionAppName  --resource-group "Share-Dev" --settings "emailRecipientsCc=test"
az functionapp config appsettings set --name $productfunctionAppName  --resource-group "Share-Dev" --settings "termsetID=test"

# Document

az functionapp config appsettings set --name $documentfunctionAppName  --resource-group "Share-Dev" --settings "appID=test"
az functionapp config appsettings set --name $documentfunctionAppName  --resource-group "Share-Dev" --settings "appSecret=test"
az functionapp config appsettings set --name $documentfunctionAppName  --resource-group "Share-Dev" --settings "AdminPortalSiteUrl=test"
az functionapp config appsettings set --name $documentfunctionAppName  --resource-group "Share-Dev" --settings "emailRecipientsTo=test"
az functionapp config appsettings set --name $documentfunctionAppName  --resource-group "Share-Dev" --settings "emailRecipientsCc=test"
az functionapp config appsettings set --name $documentfunctionAppName  --resource-group "Share-Dev" --settings "termsetID=test"

# Industries

az functionapp config appsettings set --name $industryfunctionAppName  --resource-group "Share-Dev" --settings "appID=test"
az functionapp config appsettings set --name $industryfunctionAppName  --resource-group "Share-Dev" --settings "appSecret=test"
az functionapp config appsettings set --name $industryfunctionAppName  --resource-group "Share-Dev" --settings "AdminPortalSiteUrl=test"
az functionapp config appsettings set --name $industryfunctionAppName  --resource-group "Share-Dev" --settings "emailRecipientsTo=test"
az functionapp config appsettings set --name $industryfunctionAppName  --resource-group "Share-Dev" --settings "emailRecipientsCc=test"
az functionapp config appsettings set --name $industryfunctionAppName  --resource-group "Share-Dev" --settings "termsetID=test"

# Service
az functionapp config appsettings set --name $servicestorageName  --resource-group "Share-Dev" --settings "appID=test"
az functionapp config appsettings set --name $servicestorageName  --resource-group "Share-Dev" --settings "appSecret=test"
az functionapp config appsettings set --name $servicestorageName  --resource-group "Share-Dev" --settings "AdminPortalSiteUrl=test"
az functionapp config appsettings set --name $servicestorageName  --resource-group "Share-Dev" --settings "emailRecipientsTo=test"
az functionapp config appsettings set --name $servicestorageName  --resource-group "Share-Dev" --settings "emailRecipientsCc=test"
az functionapp config appsettings set --name $servicestorageName  --resource-group "Share-Dev" --settings "termsetID=test"
