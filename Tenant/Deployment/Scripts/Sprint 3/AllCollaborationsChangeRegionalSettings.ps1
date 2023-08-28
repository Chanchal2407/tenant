cls


# connection params
# --- PROD/UAT ---
$graphappId = "ad1a97cf-acbc-48c0-a55f-b69d7f4226b2"
$certificatePath = "\certificate\UAT\AlfalavalCollaborationOnline.pfx"	# !!!
$certiPassword = "*****" | ConvertTo-SecureString -asPlainText -Force	# !!!
$AADDomain = "alfalavalonline.onmicrosoft.com"
$adminSiteURL = "https://alfalavalonline-admin.sharepoint.com"


# ----- FUNCTIONS -----

function GetAllCollaborationSites {
    # Connect
    Connect-PnPOnline -Url $adminSiteURL -ClientId $graphappId -CertificatePath $certificatePath -CertificatePassword $certiPassword -Tenant $AADDomain
    
    # Get all o365 group sites
    $result = Get-PnPTenantSite -Template GROUP#0 -Filter "Url -like '/Project-'"
    
    # Disconnect
    Disconnect-PnPOnline

    # Return
    return $result
}



# ----- BODY -----

$allSites = @()
$allSites = GetAllCollaborationSites


# Go through all sites (continue if error)
forEach ($siteObj in $allSites) {
    
    # Start site process
    Write-Host $siteObj.Url.Replace("https://alfalavalonline.sharepoint.com/", "../")


    # Connect to the site
    Write-Host " - Connect to the site " -NoNewline
    try {
        Connect-PnPOnline -Url $siteObj.Url -ClientId $graphappId -CertificatePath $certificatePath -CertificatePassword $certiPassword -Tenant $AADDomain
        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host " ERROR" -ForegroundColor Red

        # Go the the next
        continue
    }
    

    # Check regional settings
    Write-Host " - Read regional settings " -NoNewline
    $web = Get-PnPWeb -Includes RegionalSettings, RegionalSettings.TimeZones
    $localeID = $web.RegionalSettings.LocaleId
    Write-Host "OK" -ForegroundColor Green
    
    
    # Update regional settings for locale 1033
    if ($localeID -eq 1033) {
        Write-Host " - Update regional settings " -NoNewline    
        
        $context = Get-PnPContext   

        $web.RegionalSettings.LocaleId = 2057
        $web.RegionalSettings.FirstDayOfWeek = 1
        $web.RegionalSettings.Time24 = $true
        
        $web.Update()    
        $context.Load($web)
        Invoke-PnPQuery

        Write-Host "OK" -ForegroundColor Green
    }

    
    # End Site process
    Write-Host "             - - - - - - - - - -"


    # Disconnect
    Disconnect-PnPOnline
    
}