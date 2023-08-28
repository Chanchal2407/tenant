# PowerShell script to create/update Azure Function App and deploy run.ps1 as a Function in the Function app


#Declare all the parameters
param (
        [string]$resourceGroup = "test",
        [string]$storageAccount = "shareexternalsacc",
        [string]$sharedsubscription = "e60bcc2d-eb26-4ac9-86cf-406fcc666ff8",
        [string]$location = "eastus",
        [string]$runbookname,
        [string]$runbookfile,
        [string]$scheduleName,
        [string]$functionApp = "sharechanchaltest",
        [string]$runtime = "PowerShell",
        [string]$functionName = "al-externalshare-func-name",
        [string]$runFile = "run.ps1"
    )


# Check if Azure Resource group is present or not. If not, create one.
Get-AzResourceGroup -Name $resourceGroup -ErrorVariable notPresent -ErrorAction SilentlyContinue
if ($notPresent){
     Write-Host "ResourceGroup does not exist, Creating one with name $resourceGroup"
     New-AzResourceGroup -Name $resourceGroup -Location $location -Force
}
else{
    Write-Host "ResourceGroup exist"
}


# Check if Azure Storage account is present or not. If not, create one.
$STORAGE_ACCOUNT = Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccount -ErrorAction Ignore

if ($STORAGE_ACCOUNT -eq $null)  {    
    Write-Host 'Creating storage account'
    New-AzStorageAccount -ResourceGroupName $resourceGroup -AccountName $storageAccount -Location $location -SkuName Standard_LRS 
    Write-Host "$storageAccount storage account successfully created"
}
else {
    Write-Host "$storageAccount storage account already exists"
}

#Update the Azure Function App 
Get-AzFunctionApp -Name $functionApp -ResourceGroupName $resourceGroup
if($notPresent){
    Write-Host "Creating Function App"
    New-AzFunctionApp -ResourceGroupName $resourceGroup -Name $functionApp -Runtime $runtime -StorageAccountName $storageAccount -Location $location
    Write-Host "$functionApp successfully created"
}
else{
    Write-Host "Updating function-App"
    Update-AzFunctionApp -Name $functionApp -ResourceGroupName $resourceGroup -Force
    Write-Host "Function app updated"
}


# Deploy the run.ps1 file as a function in the function app
$FUNCTION_APP = Get-AzFunctionAppPlan -ResourceGroupName $resourceGroup -Name $functionApp
if($FUNCTION_APP -eq $null){
    Write-Host "Creating Function App Plan"
    New-AzFunctionAppPlan -ResourceGroupName $resourceGroup -Name $functionApp -Location $location -MinimumWorkerCount 1 -MaximumWorkerCount 10 -Sku EP1 -WorkerType Windows
    Write-Host "$functionApp Plan successfully created"
}
else{
    Write-Host "Updating function-App Plan"
    Update-AzFunctionAppPlan -ResourceGroupName $resourceGroup -Name $functionApp -MinimumWorkerCount 1 -MaximumWorkerCount 20 -Sku EP2 -Force 
    Write-Host "Function app plan updated"
} 


#New-AzFunctionApp -ResourceGroupName $resourceGroup -Name $functionName 

# Write-Host "This message is from Script1.ps1"
# $scriptPath = 'C:\External Toggler CICD\Alfa Laval\ALFA.Func.ExternalSharingToggler\O365GroupSettings\run.ps1'
# . $scriptPath
