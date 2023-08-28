cls

# connection params
# --- PROD/UAT ---
$graphappId = "ad1a97cf-acbc-48c0-a55f-b69d7f4226b2"
$certificatePath = "..\AlfalavalCollaborationOnline.pfx"
$certiPassword = "{password}" | ConvertTo-SecureString -asPlainText -Force
$AADDomain = "alfalavalonline.onmicrosoft.com"
$adminSiteURL = "https://alfalavalonline-admin.sharepoint.com"

$userToRemove = "Share.Collaboration@alfalavalonline.onmicrosoft.com"

# ----- FUNCTIONS -----

function GetAllCollaborationSites {
    # Connect
    Connect-PnPOnline -Url $adminSiteURL -ClientId $graphappId -CertificatePath $certificatePath -CertificatePassword $certiPassword -Tenant $AADDomain
    
    # Get all o365 group sites
    $result = Get-PnPTenantSite -Template GROUP#0 -Filter "Url -like 'Collaboration-'"
    # $result = Get-PnPTenantSite -Template GROUP#0 -Filter "Url -like 'Project-'"
    
    # Disconnect
    Disconnect-PnPOnline

    # Return
    return $result
}




# ----- BODY -----

$allSites = @()

Write-Host "Getting all collaboration sites... " -NoNewline
$allSites = GetAllCollaborationSites
Write-Host " OK" -ForegroundColor Green
Write-Host "             - - - - - - - - - -"

# Go through all sites (continue if error)
forEach ($siteObj in $allSites) {
    
    # Start site process
    Write-Host $siteObj.Url
    
    # Connect to the site
#    Write-Host " - Connect to the site " -NoNewline
    try {
        Connect-PnPOnline -Url $siteObj.Url -ClientId $graphappId -CertificatePath $certificatePath -CertificatePassword $certiPassword -Tenant $AADDomain
#        Write-Host " OK" -ForegroundColor Green
    } catch {
        Write-Host " ERROR" -ForegroundColor Red
        # Go the the next
        continue
    }

    # Get Group Id
#    Write-Host " - Getting group... " -NoNewline
    $currentSite = Get-PnPSite -Includes GroupId
    $groupId = $currentSite.GroupId.Guid
#    Write-Host $groupId -ForegroundColor Green

    # $classificationValue = Get-PnPProperty -ClientObject $currentSite -Property IsPublic
    
    # Disconnect
    Disconnect-PnPOnline

    # -------------------------------------------

#    Write-Host " - Reading info from group... " -NoNewline
    # Connect using app
    Connect-PnPOnline -Appid $graphappId -Appsecret $secret -AADdomain $AADDomain
        
    try {
        $currentGroup = Get-PnPUnifiedGroup -Identity $groupId
    } catch {
        Write-Host " ERROR getting group" -ForegroundColor Red
        Write-Host "             - - - - - - - - - -"
        # Go the the next
        continue
    }

    # Check if Private
    $currentGroupIsPrivate = $false
    if ($currentGroup.Visibility -eq "Private") {
        $currentGroupIsPrivate = $true
    }

    # Get owners and members
    $allOwners = Get-PnPUnifiedGroupOwners -Identity $groupId | foreach { $_.UserPrincipalName }
    $allMembers = Get-PnPUnifiedGroupMembers -Identity $groupId | foreach { $_.UserPrincipalName }
    
#    Write-Host "OK" -ForegroundColor Green


    # generate new arrays without deleted user
    $newOwners = @() 
    foreach ($owner in $allOwners) {
        if ($owner -ne $userToRemove) {
            $newOwners += $owner
        }
    }
    $newMembers = @() 
    foreach ($member in $allMembers) {
        if ($member -ne $userToRemove) {
            $newMembers += $member
        }
    }

    # update owners
    if ($newOwners.Count -eq 0) {
        Write-Host " - User is the one in the owner group" -ForegroundColor Yellow
    } elseif ($newOwners.Count -eq $allOwners.Count) {
        Write-Host " - Changes in owner group are not required" -ForegroundColor Cyan
    } else {
        # update
        Write-Host " - Removing user from owners " -NoNewline
        
        if ($currentGroupIsPrivate -eq $true) {
            Set-PnPUnifiedGroup -Identity $groupId -Owners $newOwners -IsPrivate 
        } else {
            Set-PnPUnifiedGroup -Identity $groupId -Owners $newOwners
        }

        Write-Host "OK" -ForegroundColor Green
    }

    # update members
    if ($newMembers.Count -eq 0) {
        Write-Host " - User is the one in the member group" -ForegroundColor Yellow
    } elseif ($newMembers.Count -eq $allMembers.Count) {
        Write-Host " - Changes in member group are not required" -ForegroundColor Cyan
    } else {
        # update
        Write-Host " - Removing user from members " -NoNewline
        
        if ($currentGroupIsPrivate -eq $true) {
            Set-PnPUnifiedGroup -Identity $groupId -Members $newMembers -IsPrivate 
        } else {
            Set-PnPUnifiedGroup -Identity $groupId -Members $newMembers
        }

        Write-Host "OK" -ForegroundColor Green
    }


    # End Site process
    Write-Host "             - - - - - - - - - -"
}