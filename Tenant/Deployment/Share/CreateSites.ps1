#Load SharePoint Online Prerequisits
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime") | Out-Null
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking | Out-Null

# Configuration
$TenantUrl = $Config.organizationsettings.tenantUrl
$Username = $Config.organizationsettings.username
$Password = $Config.organizationsettings.password
$SharePointAdminUrl = $Config.organizationsettings.sharePointAdminUrl

$RootSiteTitle = $Config.SiteCollections.RootSite.SiteTitle
$RootSiteUrl = $($Config.organizationsettings.tenantUrl + $Config.SiteCollections.RootSite.SiteUrl) # Note this URL must be available (check with "/_api/GroupSiteManager/GetValidSiteUrlFromAlias")
$RootSiteTemplate = $Config.SiteCollections.RootSite.SiteTemplate # "Topic" => leave empty (default), "Showcase" => "6142d2a0-63a5-4ba0-aede-d9fefca2c767" and "Blank" => "f6cc5403-0d63-442e-96c0-285923709ffc"

$AdminSiteUrl = $($Config.organizationsettings.tenantUrl + $Config.SiteCollections.AdminSite.SiteUrl)

# Connect-SPOService -Url $SharePointAdminUrl -Credential $O365Credential -ErrorAction Stop

# ----- ROOT SITE -----
Write-Host "Proceed with the root site"

# SilentlyContinue is ignored - so using alternative approach not to log error in console
try {$RootSite = Get-PnPTenantSite -Url $RootSiteUrl -ErrorAction SilentlyContinue} catch {$RootSite = $null}

if ($RootSite -ne $null -and $Config.SiteCollections.RootSite.ReCreateIfExists)
{
	Write-Host "Removing existing root site..."
	Get-PnPAppInstance | Uninstall-PnPAppInstance -Confirm:$false
	Remove-PnPTenantSite -Url $RootSiteUrl -SkipRecycleBin -ErrorAction SilentlyContinue
}

if ($Config.SiteCollections.RootSite.ReCreateIfExists -or $RootSite -eq $null)
{
	Write-Host "Creating new root site collection ($RootSiteUrl)..."
	if ($RootSiteTemplate -eq "")
	{
		$creationResult = New-PnPSite -Type CommunicationSite -Title $RootSiteTitle -Url $RootSiteUrl 
	} else {
		$creationResult = New-PnPSite -Type CommunicationSite -Title $RootSiteTitle -Url $RootSiteUrl -SiteDesignId $RootSiteTemplate
	}

	# Site has been created
	foreach($Site in $Config.SiteCollections.RootSite.Sites)
	{
	    Write-Host "Site deployment is set to true, creating sub-site "$site.SubSiteTitle -ForegroundColor Green
	    $Context = New-Object Microsoft.SharePoint.Client.ClientContext($RootSiteUrl)
	    $Context.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Username, $(ConvertTo-SecureString -AsPlainText $Password -Force))
	    $wci = New-Object Microsoft.SharePoint.Client.WebCreationInformation
	    $wci.WebTemplate = $Site.SubSiteTemplate
	    $wci.Description = $Site.Description
	    $wci.UseSamePermissionsAsParentSite = $Site.SamePermissionsAsParrentSite
	    $wci.Title = $Site.SubSiteTitle
	    $wci.Url = $Site.SubSiteUrl
	    $wci.Language = $Site.Language

	    $SubWeb = $Context.Web.Webs.Add($wci)
	    $Context.ExecuteQuery()
	    $Context.Dispose()
	}
	Write-Host "Root Site collection is being created" -ForegroundColor Green
} else {
	Write-Host "Root site collection already exists, no action is needed"
}


# ----- ADMIN SITE -----
Write-Host "Proceed with the admin site"

# SilentlyContinue is ignored - so using alternative approach not to log error in console
try {$AdminSite = Get-PnPTenantSite -Url $AdminSiteUrl -ErrorAction SilentlyContinue} catch {$AdminSite = $null}

if ($AdminSite -ne $null -and $Config.SiteCollections.AdminSite.ReCreateIfExists)
{
	Write-Host "Removing existing admin site..."
	Remove-PnPTenantSite -Url $AdminSiteUrl -SkipRecycleBin -ErrorAction SilentlyContinue
}

if ($Config.SiteCollections.AdminSite.ReCreateIfExists -or $AdminSite -eq $null)
{
	Write-Host "Creating new admin site collection ($AdminSiteUrl)..."
	if ($Config.SiteCollections.AdminSite.SiteTemplate -eq "")
	{
		$creationResult = New-PnPSite -Type CommunicationSite -Title $Config.SiteCollections.AdminSite.SiteTitle -Url $AdminSiteUrl 
	} else {
		$creationResult = New-PnPSite -Type CommunicationSite -Title $Config.SiteCollections.AdminSite.SiteTitle -Url $AdminSiteUrl -SiteDesignId $Config.SiteCollections.AdminSite.SiteTemplate
	}
	Write-Host "Admin Site collection is being created" -ForegroundColor Green
} else {
	Write-Host "Admin site collection already exists, no action is needed"
}


Write-Host "Site creation script is completed, WAIT ABOUT 1 MIN and press ENTER to continue" -ForegroundColor Yellow
Read-Host