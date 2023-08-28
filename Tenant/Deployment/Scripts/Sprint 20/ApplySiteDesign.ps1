#
#    Alfa Laval
#    Task 6082 : Script to Iterate through all Local sites and Tool sites and update Navigation setting as "Cascaded dropdown"
#

cls

# connection params
# --- DEV ---
#$graphappId = "41ef7323-ccc9-4d53-a6ba-8b66602f3ddb"
#$certificatePath = "C:\Users\dmitrijs.maslobojevs\Desktop\PnP\AllCollaboration\sprint20\certificate\DEV\ALCollaborationDEV.pfx"
#$certiPassword = "!Enter123" | ConvertTo-SecureString -asPlainText -Force
#$secret = "Nf6mNuaHTefBvukecmr3oti7FlzAV2V9nq7nScai2ho="
#$AADDomain = "fordemo.onmicrosoft.com"
#$adminSiteURL = "https://fordemo-admin.sharepoint.com"

# --- PROD/UAT ---
$graphappId = "ad1a97cf-acbc-48c0-a55f-b69d7f4226b2"
$certificatePath = "C:\Users\dmitrijs.maslobojevs\Desktop\PnP\Sprints\sprint20\certificate\UAT\AlfalavalCollaborationOnline.pfx"
$certiPassword = "1qaz!QAZ" | ConvertTo-SecureString -asPlainText -Force
$secret = "9f0ow5sXk9soMmq7aeNheTCie+qToDeMupNZeHgRM78="
$AADDomain = "alfalavalonline.onmicrosoft.com"
$adminSiteURL = "https://alfalavalonline-admin.sharepoint.com"


# Get all Tool and Local sites
$allSites = @()
Connect-PnPOnline -Url $adminSiteURL -ClientId $graphappId -CertificatePath $certificatePath -CertificatePassword $certiPassword -Tenant $AADDomain
$allSites += Get-PnPTenantSite -Template "SITEPAGEPUBLISHING#0" -Filter "Url -like '/LocalSite-'"
$allSites += Get-PnPTenantSite -Template "SITEPAGEPUBLISHING#0" -Filter "Url -like '/ToolSite-'"
Disconnect-PnPOnline

Connect-PnPOnline -Url $adminSiteURL -ClientId $graphappId -CertificatePath $certificatePath -CertificatePassword $certiPassword -Tenant $AADDomain
foreach ($siteObj in $allSites) {
    Write-Host "site:" $siteObj.Url
    # get last AlfaLaval design
    $siteDesign = $(Get-PnPSiteDesignRun -WebUrl $siteObj.Url | ? { $_.SiteDesignTitle -like '*AlfaLaval design*' }) | Select-Object -First 1
    if ($siteDesign -ne $null) {
        Write-Host "design:" $siteDesign.SiteDesignTitle
        $res = Invoke-PnPSiteDesign -Identity $siteDesign.SiteDesignId.Guid -WebUrl $siteObj.Url
        Write-Host "OK" -ForegroundColor Green
    } else {
        Write-Host "AlfaLaval design not found!" -ForegroundColor Red
    }
    Write-Host "- - - - - - -"
}
Disconnect-PnPOnline

