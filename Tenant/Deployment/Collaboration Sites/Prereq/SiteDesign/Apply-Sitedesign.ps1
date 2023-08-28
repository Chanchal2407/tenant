<#
Pre-Req : Run it in SharePoint online Management shell
          PnP powershell module must be loaded
#>

$currentPath = $(get-location).Path
$siteUrl = Read-Host "Enter admin tenant url (Ex: https://xxx-admin.sharepoint.com)"
Connect-PnPOnline -Url $siteUrl
$content = Get-Content -Path "$currentPath\theme.json" | Out-String
Add-PnPSiteScript -Title "Alfalaval theme script" -Content $content
$siteDesign = Get-PnPSiteScript | Where-Object {$_.Title -eq "Alfalaval theme script"}
if($siteDesign -ne $null){
    Add-PnPSiteDesign -Title "Alfalaval theme design" -SiteScriptIds $siteDesign.Id -WebTemplate 64    
}
Disconnect-PnPOnline