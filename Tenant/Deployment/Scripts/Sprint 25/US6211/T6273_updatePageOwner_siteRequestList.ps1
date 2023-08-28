#
#    Alfa Laval
#    User Story 6211 : Enable CLC for Learning & Training+ IT support pages
#    Task 6273 : Create script to update Page Owners/Editors base on request list
#

# ------------ input variables ------------

# QA "qa" // UAT "uat" // PROD "" 
$env = "qa" 

# Tool // Local
# Tool "SiteStatus" / / Local "shareSiteStatus"
# FIRST LETTER MUST BE HIGH CAP (used to get list and that input is case-sensitive)
$site = "Local" 
$siteStatusField = "shareSiteStatus"

# true for update // false for just read without setting values
$doUpdate = $false 


#
# connection
$url = "https://alfalavalonline.sharepoint.com/sites/" + $site.ToLower() + "sitelanding" + $env + "/"
$graphappId = "ad1a97cf-acbc-48c0-a55f-b69d7f4226b2"
$certificatePath = "C:\AlfalavalCollaborationOnline.pfx"
$certiPassword = "1qaz!QAZ" | ConvertTo-SecureString -asPlainText -Force
$AADDomain = "alfalavalonline.onmicrosoft.com"
Connect-PnPOnline -Url $url -ClientId $graphappId -CertificatePath $certificatePath -CertificatePassword $certiPassword -Tenant $AADDomain


# ------------ process data ------------
Write-Host "- - - - - - - Script started - - - - - - -"  -f Yellow
Write-Host "Landing site: " $url

$listName = "All " + $site + " sites"
$list = Get-PnPList -Identity $listName
Write-host "Request list [" $list.Title "]" -NoNewline

$items = (Get-PnPListItem -List $list).FieldValues
Write-host " with ["$items.Count"] items"

# get Tool Link content type Id (may differ in each site coll)
$toolLinkCTId = (Get-PnPContentType | ? Name -eq "Tool Link").Id.StringValue

# disconnect now, because new connections will be made for each subsite
Disconnect-PnPOnline

#
# iterate through all $site requests - they contain subsite URl, owner and editor
foreach($item in $items)
{
    Write-Host ([Environment]::NewLine) "  Request ["$item["Title"]"]"
    $subWebUrl = $item["SiteURL"].Url
    #
    # skip requests with "Tool Link" content type - these items are just simple hyperlinks that can point to any URl
    # skip requests that are Rejected (site was not created)
    # skip requests that do not have URL (most probably created for testing in QA and UAT)
    if($toolLinkCTId -ne $null -and $item.ContentTypeId.StringValue.StartsWith($toolLinkCTId)) { Write-Host "  ..skipped CT [Tool Link]" -b DarkGreen; continue; }
    if($item[$siteStatusField] -eq $null -or $item[$siteStatusField].ToString() -eq "Rejected") { Write-Host "  ..skipped Rejected" -b DarkGreen; continue; }  
    if($subWebUrl -eq $null -or $subWebUrl.Trim().Length -eq 0) { Write-Host "  ..skipped URL empty" -b DarkGreen; continue; }

    Write-Host "    Url [$subWebUrl]"
    
    #
    # extract users (if many, then first one)
    $siteOwner = "---"
    $siteOwnersCount = $item["SiteOwner"].Email.Count
    if($siteOwnersCount -eq 1) { $siteOwner = $item["SiteOwner"].Email }
    if($siteOwnersCount -gt 1) { $siteOwner = $item["SiteOwner"][0].Email }
    
    $siteEditor = "---"
    $siteEditorsCount = $item["SiteEditor"].Email.Count
    if($siteEditorsCount -eq 1) { $siteEditor = $item["SiteEditor"].Email }
    if($siteEditorsCount -gt 1) { $siteEditor = $item["SiteEditor"][0].Email }

    Write-Host "    Owner [$siteOwnersCount] -- [$siteOwner]"
    Write-Host "    Editor [$siteEditorsCount] -- [$siteEditor]"

    try
    {
        #
        # get sub site 
        Write-Host "    Connecting subweb: " -NoNewline
        Connect-PnPOnline -Url $subWebUrl -ClientId $graphappId -CertificatePath $certificatePath -CertificatePassword $certiPassword -Tenant $AADDomain
        Write-Host " OK " -b Green -f DarkGreen
 
        $fieldPageOwner = Get-PnPField -List "Site Pages" -Identity "ALFA_PageOwners" -ErrorAction SilentlyContinue
        if($fieldPageOwner -eq $null) { Write-Host "  ..skipped field ALFA_PageOwners does not exists" -b DarkGreen; continue; }
        $fieldPageEditor = Get-PnPField -List "Site Pages" -Identity "ALFA_PageEditors" -ErrorAction SilentlyContinue
        if($fieldPageEditor -eq $null) { Write-Host "  ..skipped field ALFA_PageEditors does not exists" -b DarkGreen; continue; }

        #
        # find all pages in subsite and update page owner and editor (if null)
        $items2 = Get-PnPListItem -List "Site Pages"
        Write-host "    Subsite page count ["$items2.Count"]"
        foreach($page in $items2)
        {
            $pageOwner = "---"
            $pageOwnersCount = $page["ALFA_PageOwners"].Email.Count
            if($pageOwnersCount -eq 1) { $pageOwner = $page["ALFA_PageOwners"].Email }
            if($pageOwnersCount -gt 1) { $pageOwner = $page["ALFA_PageOwners"][0].Email }
    
            $pageEditor = "---"
            $pageEditorsCount = $page["ALFA_PageEditors"].Email.Count
            if($pageEditorsCount -eq 1) { $pageEditor = $page["ALFA_PageEditors"].Email }
            if($pageEditorsCount -gt 1) { $pageEditor = $page["ALFA_PageEditors"][0].Email }
            
            $pageTitle = $page["Title"]
            Write-host "       Page [$pageTitle] owner [$pageOwner] and editor [$pageEditor]" -NoNewline

            $wasUpdated = $false
            if($doUpdate -eq $true)
            {
                #
                # Owner
                if($pageOwner -eq "---")
                {
                    if($siteOwner -eq "---") { Write-Host ([Environment]::NewLine) "  ..skipped SiteOwner is empty" -b DarkGreen; continue; }
                    else
                    {
                        # ensure user is available to current site
                        $userOwner = $null
                        $userOwner = Get-PnPUser | ? Email -eq $siteOwner
                        if($userOwner -eq $null) { New-PnPUser -LoginName $siteOwner }

                        Set-PnPListItem -List "Site Pages" -Identity $page.Id -Values @{ "ALFA_PageOwners" = $siteOwner } > $null
                        Write-host " --owner " -b DarkGreen -f Green -NoNewline
                        $wasUpdated = $true
                    }
                }

                #
                # Editor
                if($pageEditor -eq "---")
                {
                    if($siteEditor -eq "---") { Write-Host ([Environment]::NewLine) "  ..skipped SiteEditor is empty" -b DarkGreen; continue; }
                    else
                    {
                        # ensure user is available to current site
                        $userEditor = $null
                        $userEditor = Get-PnPUser | ? Email -eq $siteEditor
                        if($userEditor -eq $null) { New-PnPUser -LoginName $siteEditor }

                        Set-PnPListItem -List "Site Pages" -Identity $page.Id -Values @{ "ALFA_PageEditors" = $siteEditor } > $null
                        Write-host " --editor " -b DarkGreen -f Green
                        $wasUpdated = $true
                    }
                }
            }
            
            if($wasUpdated -eq $false) { Write-Host "" } #just for the looks :)
        }
    }
    catch 
    {
        Write-Host "Unknown exception" -b Red
    }
    finally
    {
        Disconnect-PnPOnline
    }   
}

Write-Host "- - - - - - - Script ended - - - - - - -"  -f Yellow