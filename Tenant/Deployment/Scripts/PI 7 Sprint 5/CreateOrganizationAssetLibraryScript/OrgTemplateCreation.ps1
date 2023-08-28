cls
# Reading setting file
$Config = (Get-Content "SiteConfig.json") | Out-String | ConvertFrom-Json
if ($Config.OrganizationSettings.askCredentials)
{
	$O365Credential = Get-Credential
}
else
{
	$securePassword = ConvertTo-SecureString $Config.OrganizationSettings.password –AsPlainText –force
	$O365Credential = New-Object System.Management.Automation.PsCredential($Config.OrganizationSettings.username, $securePassword)
}

#Load SharePoint Online Prerequisits
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime") | Out-Null
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking | Out-Null

# Configuration
$OrgAssetSiteUrl = $($Config.organizationsettings.tenantUrl + $Config.SiteCollections.OrganiationAssetSite.SiteUrl)
$OrganiationAssetListTemplate = $Config.SiteCollections.OrganiationAssetSite.OrganiationAssetListTemplate

Connect-PnPOnline -Url $($Config.organizationSettings.tenantUrl) -Credentials $O365Credential -ErrorAction Stop

# ----- ORGANIZATION ASSET SITE -----
Write-Host "Proceed with the organization asset site"

# SilentlyContinue is ignored - so using alternative approach not to log error in console
try {$OrgAssetSite = Get-PnPTenantSite -Url $OrgAssetSiteUrl -ErrorAction SilentlyContinue} catch {$OrgAssetSite = $null}

if ($OrgAssetSite -ne $null -and $Config.SiteCollections.OrganiationAssetSite.ReCreateIfExists)
{
	Write-Host "Removing existing OrgAsset site..."
	Remove-PnPTenantSite -Url $OrgAssetSiteUrl -SkipRecycleBin -ErrorAction SilentlyContinue
}

if ($Config.SiteCollections.OrganiationAssetSite.ReCreateIfExists -or $OrgAssetSite -eq $null)
{
	Write-Host "Creating new Organiation Asset Site collection ($OrgAssetSiteUrl)..."
	if ($Config.SiteCollections.OrganiationAssetSite.SiteTemplate -eq "")
	{
		$creationResult = New-PnPSite -Type CommunicationSite -Title $Config.SiteCollections.OrganiationAssetSite.SiteTitle -Url $OrgAssetSiteUrl 
	} else {
		$creationResult = New-PnPSite -Type CommunicationSite -Title $Config.SiteCollections.OrganiationAssetSite.SiteTitle -Url $OrgAssetSiteUrl -SiteDesignId $Config.SiteCollections.OrganiationAssetSite.SiteTemplate
	}
	Write-Host "Orgnization Asset Site collection is being created" -ForegroundColor Green
} else {
	Write-Host "Orgnization Asset site collection already exists, no action is needed"
}


Write-Host "Site creation script is completed, WAIT ABOUT 1 MIN and press ENTER to continue" -ForegroundColor Yellow
Read-Host

Disconnect-PnPOnline

# --- ORGANIZATION ASSET SITE ---
Write-Host "Applying template for the organization asset site..."
Connect-PnPOnline -Url $($Config.OrganizationSettings.tenantUrl + $Config.SiteCollections.OrganiationAssetSite.SiteUrl) -Credentials $O365Credential -ErrorAction Stop

#Add 'Everyone Except External Users' to visitors group
$realm = Get-PnPAuthenticationRealm
$loginName = "c:0-.f|rolemanager|spo-grid-all-users/$realm"
$group = Get-PnPGroup -AssociatedVisitorGroup
Add-PnPUserToGroup -LoginName $loginName -Identity $group

#Run cmdlet to apply template
Apply-PnPProvisioningTemplate -Path $OrganiationAssetListTemplate -ErrorAction Stop

Disconnect-PnPOnline

#POST TEMPLATE ACTIONS (Which are not possible to include in template)
Write-Host "Applying post template actions..."

#Connect to Admin site
Connect-PnPOnline -Url $($Config.organizationSettings.sharePointAdminUrl) -Credentials $O365Credential -ErrorAction Stop

# Create Organization Asset Library
Add-PnPOrgAssetsLibrary -LibraryUrl $($Config.OrganizationSettings.tenantUrl + $Config.SiteCollections.OrganiationAssetSite.SiteUrl + $Config.SiteCollections.OrganiationAssetSite.OrgAssetLibrary) -ThumbnailURL $($Config.OrganizationSettings.tenantUrl + $Config.SiteCollections.OrganiationAssetSite.SiteUrl + $Config.SiteCollections.OrganiationAssetSite.OrgAssetLibrary + $Config.SiteCollections.OrganiationAssetSite.ImageTitle) -CdnType Public

Disconnect-PnPOnline