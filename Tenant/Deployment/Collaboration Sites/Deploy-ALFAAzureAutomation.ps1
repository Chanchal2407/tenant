<# 
----------------------------------------------------------------------------
Deploys resources to Azure Automation, Installs PnP.PowerShell
Created:      Gurudatt Bhat ( referenced from solution posted by Paul Bullock)
Date:         04/06/2021
Modification History:
Ravi Rachchh (19/09/2022)
1. Code added for installing MSAL.PS package in azure runbook.

.Notes
    Pre-Req: Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force    
    
    Default App Scopes: Sites.FullControl.All, Group.ReadWrite.All, User.Read.All
    References: 
        https://pnp.github.io/powershell/cmdlets/nightly/Register-PnPAzureADApp.html
        https://docs.microsoft.com/en-us/powershell/module/az.automation/New-AzAutomationCredential?view=azps-4.4.0
 ----------------------------------------------------------------------------
#>

[CmdletBinding()]
param (
    
    [Parameter(Mandatory = $true)]
    [string] $Tenant, #yourtenant.onmicrosoft.com

    [Parameter(Mandatory = $true)]
    [string] $TenantUrl, # https://[thispart].sharepoint.com

    [Parameter(Mandatory = $true)]
    [string] $SiteDirectorySiteUrl, # https://[thispart].sharepoint.com

    [Parameter(Mandatory = $true)]
    [string] $SiteDirectoryList,

    [Parameter(Mandatory = $true)]
    [string] $TemplateConfigurationsList,

    [Parameter(Mandatory = $true)]
    [string] $BaseModulesLibrary,

    [Parameter(Mandatory = $true)]
    [string] $TimerIntervalMinutes,

    [Parameter(Mandatory = $true)]
    [string] $ColumnPrefix,

    [Parameter(Mandatory = $true)]
    [string] $TenantAdminUrl,

    [Parameter(Mandatory = $true)]
    [string] $SupportGroupName,

    [Parameter(Mandatory = $true)]
    [string] $CertificatePass, # <-- Use a nice a super complex password

    [Parameter(Mandatory = $true)]
    [string] $AzureAppId,

    [Parameter(Mandatory = $true)]
    [string] $CertificatePath = "C:\code\dev\vNextCollaborationSites\Enginev2\PnP.PowerShell Automation AA.pfx", # e.g. "C:\Git\tfs\Script-Library\Azure\Automation\Deploy\PnP-PowerShell Automation.pfx"   

    [Parameter(Mandatory = $true)]
    [string] $TargetEnv,

    [Parameter(Mandatory = $true)]
    [string] $SiteDesignId,

    [Parameter(Mandatory = $true)]
    [string] $AzureResourceGroupName = "ShareDev",

    [Parameter(Mandatory = $false)]
    [string] $AzureRegion = "northeurope",

    [Parameter(Mandatory = $true)]
    [string] $AzureAutomationName = "pnp-collaborationsiteproisioning-powershell-auto123",

    [Parameter(Mandatory = $true)]
    [string] $SubscriptionId = "e02110eb-52ff-4e3d-a36b-637978da4d54",

    [Parameter(Mandatory = $true)]
    [boolean] $CreateResourceGroup,
    
    [Parameter(Mandatory = $true, HelpMessage="Type Y/N ")]
    [string] $UpdateExistingRunbook

)


begin {
  
   
    Write-Host "Let's get started..."
      
}
process {

    # ----------------------------------------------------------------------------------
    #   Azure - Connect to Azure
    # ----------------------------------------------------------------------------------
    Write-Host " - Connecting to Azure..." -ForegroundColor Cyan
    Connect-AzAccount -Subscription $SubscriptionId

    # ----------------------------------------------------------------------------------
    #   Azure - Resource Group
    # ----------------------------------------------------------------------------------
    #Check if its just updating existing Runbook
    Write-Host $UpdateExistingRunbook
    if ("Y" -eq $UpdateExistingRunbook) {
        # Add Azure Runbook
        Write-Host " - Importing and publishing the runbook..." -ForegroundColor Cyan

        # Import automation runbooks
        $proisioningRunbookName = "NewTeamSiteProvision"
    
  
        # Add NewTeamsSiteProision to  Azure Automation
        Import-AzAutomationRunbook `
            -Force `
            -Name $proisioningRunbookName `
            -Path "./EngineV2/$($proisioningRunbookName).ps1" `
            -ResourceGroupName $AzureResourceGroupName `
            -AutomationAccountName $AzureAutomationName `
            -Type PowerShell
           



        # Publish runbooks
        Publish-AzAutomationRunbook `
            -Name $proisioningRunbookName `
            -ResourceGroupName $AzureResourceGroupName `
            -AutomationAccountName $AzureAutomationName

        Write-Host "Finished updating site proisioning runbook" -ForegroundColor Green
    }
    else {
        # Check if the Resource Group exists
        if ($CreateResourceGroup) {
            Write-Host " - Creating Resource Group..." -ForegroundColor Cyan
            New-AzResourceGroup -Name $AzureResourceGroupName -Location $AzureRegion
        }
        
        # ----------------------------------------------------------------------------------
        #   Azure Automation - Creation
        # ----------------------------------------------------------------------------------

        # Validate this does not already exist
        $existingAzAutomation = Get-AzAutomationAccount | Where-Object AutomationAccountName -eq $AzureAutomationName
        if ($null -ne $existingAzAutomation) {
            Write-Error " - Automation account already exists...aborting deployment script" # Stop the script, already exists
            return #End the Script
        }

        Write-Host " - Creating Azure Automation Account..." -ForegroundColor Cyan

        # Note: Not all regions support Azure Automation - check here for your region: 
        #   https://azure.microsoft.com/en-us/global-infrastructure/services/?products=automation&regions=all
        New-AzAutomationAccount `
            -Name $AzureAutomationName `
            -Location $AzureRegion `
            -ResourceGroupName $AzureResourceGroupName

        # ----------------------------------------------------------------------------------
        #   Azure Automation - Add Modules
        # ----------------------------------------------------------------------------------
    
        # Add PnP Modules - July 2020 Onwards
        New-AzAutomationModule `
            -AutomationAccountName $AzureAutomationName `
            -Name "PnP.PowerShell" `
            -ContentLink "https://devopsgallerystorage.blob.core.windows.net/packages/pnp.powershell.1.7.0.nupkg" `
            -ResourceGroupName $AzureResourceGroupName

        # Add MSAL.PS - Changed by Ravi Rachchh for teams creation code
        New-AzAutomationModule `
            -AutomationAccountName $AzureAutomationName `
            -Name "MSAL.PS" `
            -ContentLink "https://www.powershellgallery.com/api/v2/package/msal.ps/4.37.0" `
            -ResourceGroupName $AzureResourceGroupName

    
        # ----------------------------------------------------------------------------------
        #   Azure Automation - Create variables
        # ----------------------------------------------------------------------------------
        New-AzAutomationVariable `
            -AutomationAccountName $AzureAutomationName `
            -Name "AppClientId" `
            -Encrypted $False `
            -Value $AzureAppId `
            -ResourceGroupName $AzureResourceGroupName
    
        New-AzAutomationVariable `
            -AutomationAccountName $AzureAutomationName `
            -Name "AppAdTenant" `
            -Encrypted $true `
            -Value $Tenant `
            -ResourceGroupName $AzureResourceGroupName

        New-AzAutomationVariable `
            -AutomationAccountName $AzureAutomationName `
            -Name "TenantUrl" `
            -Encrypted $false `
            -Value $TenantUrl `
            -ResourceGroupName $AzureResourceGroupName

        New-AzAutomationVariable `
            -AutomationAccountName $AzureAutomationName `
            -Name "SiteDirectorySiteUrl" `
            -Encrypted $false `
            -Value $SiteDirectorySiteUrl `
            -ResourceGroupName $AzureResourceGroupName

        New-AzAutomationVariable `
            -AutomationAccountName $AzureAutomationName `
            -Name "SiteDirectoryList" `
            -Encrypted $false `
            -Value $SiteDirectoryList `
            -ResourceGroupName $AzureResourceGroupName

        New-AzAutomationVariable `
            -AutomationAccountName $AzureAutomationName `
            -Name "TemplateConfigurationsList" `
            -Encrypted $false `
            -Value $TemplateConfigurationsList `
            -ResourceGroupName $AzureResourceGroupName

        New-AzAutomationVariable `
            -AutomationAccountName $AzureAutomationName `
            -Name "BaseModulesLibrary" `
            -Encrypted $false `
            -Value $BaseModulesLibrary `
            -ResourceGroupName $AzureResourceGroupName

        New-AzAutomationVariable `
            -AutomationAccountName $AzureAutomationName `
            -Name "TimerIntervalMinutes" `
            -Encrypted $false `
            -Value $TimerIntervalMinutes `
            -ResourceGroupName $AzureResourceGroupName

        New-AzAutomationVariable `
            -AutomationAccountName $AzureAutomationName `
            -Name "TenantAdminUrl" `
            -Encrypted $true `
            -Value $TenantAdminUrl `
            -ResourceGroupName $AzureResourceGroupName

        New-AzAutomationVariable `
            -AutomationAccountName $AzureAutomationName `
            -Name "ColumnPrefix" `
            -Encrypted $false `
            -Value $ColumnPrefix `
            -ResourceGroupName $AzureResourceGroupName

        New-AzAutomationVariable `
            -AutomationAccountName $AzureAutomationName `
            -Name "SupportGroupName" `
            -Encrypted $false `
            -Value $SupportGroupName `
            -ResourceGroupName $AzureResourceGroupName

        New-AzAutomationVariable `
            -AutomationAccountName $AzureAutomationName `
            -Name "TargetEnv" `
            -Encrypted $false `
            -Value $TargetEnv `
            -ResourceGroupName $AzureResourceGroupName

        New-AzAutomationVariable `
            -AutomationAccountName $AzureAutomationName `
            -Name "SiteDesignId" `
            -Encrypted $false `
            -Value $SiteDesignId `
            -ResourceGroupName $AzureResourceGroupName

        $CertificatePassword = ConvertTo-SecureString -String $CertificatePass -AsPlainText -Force
        New-AzAutomationCertificate `
            -Name "AzureAppCertificate" `
            -Description "Certificate for PnP PowerShell automation" `
            -Password $CertificatePassword `
            -Path $CertificatePath `
            -Exportable `
            -ResourceGroupName $AzureResourceGroupName `
            -AutomationAccountName $AzureAutomationName

        # Azure App certificate. In this case, User object is not used
        $User = "IAamNotUsed"
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $CertificatePassword
        New-AzAutomationCredential `
            -Name "AzureAppCertPassword" `
            -Description "Contains the password for the certificate" `
            -Value $Credential `
            -ResourceGroupName $AzureResourceGroupName `
            -AutomationAccountName $AzureAutomationName `

        # Add Azure Runbook
        Write-Host " - Importing and publishing example runbook..." -ForegroundColor Cyan

        # Import automation runbooks
        $proisioningRunbookName = "NewTeamSiteProvision"
    
  
        # Add NewTeamsSiteProision to  Azure Automation
        Import-AzAutomationRunbook `
            -Name $proisioningRunbookName `
            -Path "./EngineV2/$($proisioningRunbookName).ps1" `
            -ResourceGroupName $AzureResourceGroupName `
            -AutomationAccountName $AzureAutomationName `
            -Type PowerShell



        # Publish runbooks
        Publish-AzAutomationRunbook `
            -Name $proisioningRunbookName `
            -ResourceGroupName $AzureResourceGroupName `
            -AutomationAccountName $AzureAutomationName

        Write-Host "Finished adding site proisioning runbook" -ForegroundColor Green
    

    }
    
}
end {

    Write-Host "All done! :)" -ForegroundColor Green
}