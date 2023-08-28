cls


# connection params
# --- PROD/UAT ---
$graphappId = "ad1a97cf-acbc-48c0-a55f-b69d7f4226b2"
$certificatePath = "\certificate\UAT\AlfalavalCollaborationOnline.pfx"	# !!!
$certiPassword = "*****" | ConvertTo-SecureString -asPlainText -Force	# !!!
$AADDomain = "alfalavalonline.onmicrosoft.com"
$adminSiteURL = "https://alfalavalonline-admin.sharepoint.com"
$connectedUser = "your_user@alfalaval.com"								# !!!



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


function UpdateAccessRequestSettings {
    param ([string]$siteUrl)
        
    # Settings URL
    $settingsUrl = $siteUrl + "/_layouts/15/setrqacc.aspx?type=web"

    # Open IE
    $ie = New-Object -ComObject 'internetExplorer.Application'
    $ie.Visible= $true
    $ie.Navigate($settingsUrl)

    while ($ie.Busy -eq $true) { Start-Sleep -seconds 2; }

    # click radio button
    # $radio = $ie.Document.getElementByID('ctl00_PlaceHolderMain_ctl00_ctl04_defaultValue')
    $radio = $ie.Document.IHTMLDocument3_getElementByID('ctl00_PlaceHolderMain_ctl00_ctl04_defaultValue')
    $radio.setActive()
    $radio.click()

    Start-Sleep -seconds 2;

    # click Save
    $submit=$ie.Document.IHTMLDocument3_getElementByID("ctl00_PlaceHolderMain_ctl01_RptControls_btnSubmit")
    $submit.click()

    # close IE
    Start-Sleep -seconds 3;
    $ie.Quit()
    
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

    # Check if user is admin
    Write-Host " - Check if user is admin " -NoNewline
    $userIsAdmin = Get-PnPSiteCollectionAdmin | % { $_.Email -eq $connectedUser }
    Write-Host "OK" -ForegroundColor Green

    # Set user as admin
    if ($userIsAdmin -eq $false) {
        Write-Host " - Set user as admin " -NoNewline
        Add-PnPSiteCollectionAdmin -Owners $connectedUser
        Write-Host "OK" -ForegroundColor Green
    }


    # Update Access Request settings
    Write-Host " - Update request access e-mails " -NoNewline
    UpdateAccessRequestSettings -siteUrl $siteObj.Url
    Write-Host "OK" -ForegroundColor Green


    # Remove user from admin
    if ($userIsAdmin -eq $false) {
        Write-Host " - Remove user from admin " -NoNewline
        Remove-PnPSiteCollectionAdmin -Owners $connectedUser
        Write-Host "OK" -ForegroundColor Green
    }
    

    # Disconnect
    Disconnect-PnPOnline


    # End Site process
    Write-Host "             - - - - - - - - - -"
    
}