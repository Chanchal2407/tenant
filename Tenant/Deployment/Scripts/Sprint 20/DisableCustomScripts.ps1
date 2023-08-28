cls

# connection params
# --- DEV ---
#$graphappId = "41ef7323-ccc9-4d53-a6ba-8b66602f3ddb"
#$certificatePath = "C:\Users\dmitrijs.maslobojevs\Desktop\PnP\AllCollaboration\sprint20\certificate\DEV\ALCollaborationDEV.pfx"
#$certiPassword = "!Enter123" | ConvertTo-SecureString -asPlainText -Force
#$AADDomain = "fordemo.onmicrosoft.com"
#$adminSiteURL = "https://fordemo-admin.sharepoint.com"
#$connectedUser = "dmitrijs@fordemo.onmicrosoft.com"

# --- PROD/UAT ---
$graphappId = "ad1a97cf-acbc-48c0-a55f-b69d7f4226b2"
$certificatePath = "C:\Users\dmitrijs.maslobojevs\Desktop\PnP\AllCollaboration\sprint3\certificate\UAT\AlfalavalCollaborationOnline.pfx"
$certiPassword = "1qaz!QAZ" | ConvertTo-SecureString -asPlainText -Force
$AADDomain = "alfalavalonline.onmicrosoft.com"
$adminSiteURL = "https://alfalavalonline-admin.sharepoint.com"
$connectedUser = "dmitrijs.maslobojevs@alfalaval.com"



# ----- FUNCTIONS -----

function GetAllCollaborationSites {
     
    # Get all o365 group sites
    $result = Get-PnPTenantSite -Template GROUP#0 -Filter "Url -like '/UAT-Collaboration-'"
    
    # Return
    return $result
}

# ----- BODY -----
Write-Host "- - - - - - - Script started - - - - - - -"  -ForegroundColor Yellow

# Connect
Connect-PnPOnline -Url $adminSiteURL -ClientId $graphappId -CertificatePath $certificatePath -CertificatePassword $certiPassword -Tenant $AADDomain
   
$cnt = 0
$allSites = @()
$allSites = GetAllCollaborationSites


# Go through all sites (continue if error)
forEach ($siteObj in $allSites) {
    
    if ($($siteObj.DenyAddAndCustomizePages) -ne "Enabled") {
        Write-Host $siteObj.Url.Replace("https://alfalavalonline.sharepoint.com/sites/", "") -NoNewline      
        Write-Host "" $($siteObj.DenyAddAndCustomizePages) -NoNewline
                
        $DenyAddAndCustomizePagesStatusEnum = [Microsoft.Online.SharePoint.TenantAdministration.DenyAddAndCustomizePagesStatus]
        $siteObj.DenyAddAndCustomizePages = $DenyAddAndCustomizePagesStatusEnum::Enabled
        $siteObj.Update()
        Invoke-PnPQuery
        
        Write-Host " OK" -ForegroundColor Green

        $cnt++
    }
}

# Disconnect
Disconnect-PnPOnline

Write-Host "- - - - - - Script completed - - - - - - -" -ForegroundColor Yellow
Write-Host "$cnt sites from $($allSites.Count) have incorrect sharing settings"

# 