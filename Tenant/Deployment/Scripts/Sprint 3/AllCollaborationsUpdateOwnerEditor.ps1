cls

# params
$propertybagAlternativeList = "PropertyBagAlternatives"

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
    # $result = Get-PnPTenantSite -Template GROUP#0
    
    # Disconnect
    Disconnect-PnPOnline

    # Return
    return $result
}


function GetUserFromJsonString {
    param ([string]$jsonKey, [string]$jsonString)

    $allUsers = @()
    $jsonObj = ConvertFrom-Json -InputObject $jsonValues

    $jsonEnum = $jsonObj.GetEnumerator()
    while ($jsonEnum.MoveNext()) {
        $jsonCurrent = $jsonEnum.Current
        if ($jsonCurrent.Key -eq $jsonKey) {
            $($jsonCurrent.Value.Data -split "#") | % {
                $allUsers += ($_.Substring($_.IndexOf("|")+1))
            }
        }
    }
        
    # alfabetically
    # return @($allUsers | Sort-Object)[0]

    # first typed
    return @($allUsers)[0]
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
               

    # Read hidden list
    Write-Host " - Read 'PropertyBagAlternatives' list " -NoNewline
    
    $jsonValues = ""
    $itemOwnerId = -1
    $itemEditorId = -1
    
    $listItems = (Get-PnPListItem -List $propertybagAlternativeList -ErrorAction SilentlyContinue -Fields "Title","PropertyBagValuesJSON") 
        
    if ($listItems -eq $null) {
        Write-Host "List not found or empty!" -ForegroundColor Red
        
        # End site process
        Write-Host "             - - - - - - - - - -"
        Disconnect-PnPOnline
        
        # Go to the next site
        continue
    } else {
        $listItems | % {
            if ($_["Title"] -eq "ProjectMetadata") {
                $jsonValues = $_["PropertyBagValuesJSON"]
            }
            if ($_["Title"] -eq "SiteOwner") {
                $itemOwnerId = $_.ID
            }
            if ($_["Title"] -eq "SiteEditor") {
                $itemEditorId = $_.ID
            }
        }
    }
    Write-Host "OK" -ForegroundColor Green
    

    # Get site owner
    Write-Host " - Get site owner " -NoNewline
    $siteOwner = GetUserFromJsonString -jsonKey "-SiteDirectory_SiteOwners-" -jsonString $jsonValues
    Write-Host $siteOwner -ForegroundColor Green

    # Get site editor
    Write-Host " - Get site editor " -NoNewline
    $siteEditor = GetUserFromJsonString -jsonKey "-SiteDirectory_SiteEditors-" -jsonString $jsonValues
    Write-Host $siteEditor -ForegroundColor Green

    
    # Add or Update list items
    Write-Host " - Update owner and editor " -NoNewline
    try {
        # Update owner
        if($itemOwnerId -gt 0) {
            $result = Set-PnPListItem -Identity $itemOwnerId -List $propertybagAlternativeList -Values @{"Title"="SiteOwner";"PropertyBagValuesJSON"=$siteOwner}
        }
        else{
            $result =  Add-PnPListItem -List $propertybagAlternativeList -Values @{"Title"="SiteOwner";"PropertyBagValuesJSON"=$siteOwner}
        }

        # Update editor
        if($itemEditorId -gt 0) {
            $result = Set-PnPListItem -Identity $itemEditorId -List $propertybagAlternativeList -Values @{"Title"="SiteEditor";"PropertyBagValuesJSON"=$siteEditor}
        }
        else{
            $result = Add-PnPListItem -List $propertybagAlternativeList -Values @{"Title"="SiteEditor";"PropertyBagValuesJSON"=$siteEditor}
        }

        Write-Host "OK" -ForegroundColor Green
    } catch {
        Write-Host "Error!" -ForegroundColor Red
    }



    # End Site process
    Write-Host "             - - - - - - - - - -"


    # Disconnect
    Disconnect-PnPOnline
    
}