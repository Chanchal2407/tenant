# Pre-requisites:
# Install the following packages to run this script:
# SharePointPnPPowerShellOnline.msi : https://github.com/SharePoint/PnP-PowerShell/releases
# SharePoint Online Management Shell : https://www.microsoft.com/en-us/download/details.aspx?id=35588
# Add account admin to Termstore admins

try {

	# Reading setting file
	$Config = (Get-Content "SiteConfig.json") | Out-String | ConvertFrom-Json
	if ($Config.OrganizationSettings.askCredentials)
	{
		$O365Credential = Get-Credential
	}
	else
	{
		$securePassword = ConvertTo-SecureString $Config.organizationsettings.password –AsPlainText –force
		$O365Credential = New-Object System.Management.Automation.PsCredential($Config.organizationsettings.username, $securePassword)
	}
	Connect-PnPOnline -Url $Config.organizationsettings.sharePointAdminUrl -Credentials $O365Credential -ErrorAction Stop

	#Define proper environment
    Write-Host "Environment: " $Config.OrganizationSettings.environment	
	$EnvPrefix=""; #default for prod
	if ($Config.OrganizationSettings.environment -ne "PROD")
	{
		$EnvPrefix = "-"+$Config.OrganizationSettings.environment.ToLower();
	}

	$EnvPrefixApp = "-" + $Config.OrganizationSettings.environment.ToLower();

	#Run script for new termsets
	& ".\ConfigureTermSets.ps1"
	#Run script for site provisioning
	& ".\CreateSites.ps1"
	#Run script for CDN
	& ".\PrepareCDN.ps1"

	# Task 149433 - Make new site (Share Home site) as SharePoint home site
	$RootSiteUrl = $($Config.organizationsettings.tenantUrl + $Config.SiteCollections.RootSite.SiteUrl)
	Connect-PnPOnline -Url $Config.organizationsettings.sharePointAdminUrl -Credentials $O365Credential -ErrorAction Stop
    Set-PnPHomeSite -Url $RootSiteUrl

	# --- ADMIN SITE ---
	Write-Host "Applying template for the admin site..."
	Connect-PnPOnline -Url $($Config.organizationSettings.tenantUrl + $Config.SiteCollections.AdminSite.SiteUrl) -Credentials $O365Credential -ErrorAction Stop
	#Run cmdlet to apply template
	Apply-PnPProvisioningTemplate -Path "AdminSiteTemplate.xml" -ErrorAction Stop
	Disconnect-PnPOnline


	# --- ROOT SITE ---
	Connect-PnPOnline -Url $($Config.organizationSettings.tenantUrl + $Config.SiteCollections.RootSite.SiteUrl) -Credentials $O365Credential -ErrorAction Stop
	
	Write-Host "Installing apps.."
	$AllApps = Get-PnpApp
	$AllApps | Where-Object {$_.Title -eq "Share News Portal Web Parts$EnvPrefixApp"} | Install-PnPApp -ErrorAction SilentlyContinue
	$AllApps | Where-Object {$_.Title -eq "Share Startpage Web Parts$EnvPrefixApp"} | Install-PnPApp -ErrorAction SilentlyContinue
	
	Write-Host "Applying template for the root site..."
	#Run cmdlet to apply template
	Apply-PnPProvisioningTemplate -Path "RootSiteTemplate.xml" -ErrorAction Stop

	#POST TEMPLATE ACTIONS (Which are not possible to include in template)
	Write-Host "Applying post template actions..."

	#Add Indexed columns:
	foreach ($field in @("Title","Author","Created","Modified","Editor"))
	{
		$InField = Get-PnPField -List "Site Pages" -Identity $field
		$InField.Indexed=$true
		$InField.Update()
		$InField.Context.ExecuteQuery()
	}
	foreach ($field in @("Title","Author"))
	{
		$InField = Get-PnPField -List "My Links" -Identity $field
		$InField.Indexed=$true
		$InField.Update()
		$InField.Context.ExecuteQuery()
	}

	# Remove-PnPContentTypeFromList -List "ShareCampaigns" -ContentType "Picture" -ErrorAction Stop
	Remove-PnPContentTypeFromList -List "My Links" -ContentType "Item" -ErrorAction Stop

	# Create news pages - do not replace if exist
	if ((Get-PnPClientSidePage -Identity "News Templates/NewsTemplate" -ErrorAction SilentlyContinue) -eq $null){
		$NewsPage = Add-PnPClientSidePage -Name "News Templates/NewsTemplate" -ErrorAction Stop
		Set-PnPListItem -List "SitePages" -Identity $($NewsPage.PageListItem.Id) -ContentType "News" -Values @{"Title"="News title"} -ErrorAction Stop
		$NewsPage.Publish()
		$NewsPage.Context.ExecuteQuery()
	}
	if ((Get-PnPClientSidePage -Identity "Corporate News Templates/CorporateNewsTemplate" -ErrorAction SilentlyContinue) -eq $null){
		$CNewsPage = Add-PnPClientSidePage -Name "Corporate News Templates/CorporateNewsTemplate" -ErrorAction Stop
		Set-PnPListItem -List "SitePages" -Identity $($CNewsPage.PageListItem.Id) -ContentType "Corporate News" -Values @{"Title"="Corporate news title"} -ErrorAction Stop
		$CNewsPage.Publish()
		$CNewsPage.Context.ExecuteQuery()
	}

	# Add web-parts to News Portal page
	$NewsPortalPage = Get-PnPClientSidePage -Identity "NewsPortal" -ErrorAction SilentlyContinue
	if ($NewsPortalPage -eq $null)
	{
		$NewsPortalPage = Add-PnPClientSidePage -Name "NewsPortal" -ErrorAction Stop
		Set-PnPListItem -List SitePages –Identity $($NewsPortalPage.PageListItem.Id) -Values @{"Title"="News Portal"; "PageLayoutType"="Home"} -ErrorAction Stop 
	}
	if ( $(Get-PnPClientSideComponent -Page "NewsPortal" | Where-Object {$_.Title -like "News portal*"}) -eq $null) {
		Add-PnPClientSidePageSection -Page "NewsPortal" -Order 1 -SectionTemplate OneColumn
		Add-PnPClientSideWebPart -Page "NewsPortal" -Section 1 -Column 1 -Component "News Portal$EnvPrefix" -Order 1
	}
	
	#  Add web-parts to Home Page
	Add-PnPClientSidePageSection -Page "Home" -Order 1 -SectionTemplate OneColumn
	if ( $(Get-PnPClientSideComponent -Page "Home" | Where-Object {$_.Title -like "Share News*"}) -eq $null) {
		Add-PnPClientSideWebPart -Page "Home" -Section 1 -Column 1 -Component "Share News$EnvPrefix" -Order 1
	}
	if ( $(Get-PnPClientSideComponent -Page "Home" | Where-Object {$_.Title -like "Campaigns*"}) -eq $null) {
		Add-PnPClientSideWebPart -Page "Home" -Section 1 -Column 1 -Component "Campaigns$EnvPrefix" -Order 2
	}
	if ( $(Get-PnPClientSideComponent -Page "Home" | Where-Object {$_.Title -like "My Links*"}) -eq $null) {
		Add-PnPClientSideWebPart -Page "Home" -Section 1 -Column 1 -Component "My Links$EnvPrefix" -Order 3
	}
	
	# Publish pages
	$NewsPortalPage = Set-PnPClientSidePage -Identity "NewsPortal" -Publish
	$HomePage = Set-PnPClientSidePage -Identity "Home" -Publish
	
	Write-Host "Please proceed with manual step:" -ForegroundColor Yellow
	Write-Host " - User Profile Property creation" -ForegroundColor Yellow
	
	#Run script for Extensions (Top Nav)
	& ".\AttachExtensions.ps1"

	# Message to ensure Highlighting configuration are needed
	Write-Host "After deployment please ensure that Highlighting configuration for Top Navigation is not needed!" -ForegroundColor Yellow
	Write-Host "See '2.5. Top Navigation' section in the 'New Share o365 Documentation' for details" -ForegroundColor Yellow
	Write-Host ""
	$null = Read-Host "Press ENTER to finish deployment"
	
	Write-Host "--- DONE ---" -ForegroundColor Green
}
catch {
	Write-Host "EXCEPTION HAPPENED IN THE SCRIPT: $($_.InvocationInfo.ScriptName)" -ForegroundColor Red
	Write-Host "EXCEPTION HAPPENED IN THE LINE: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
	Read-Host $_.Exception.Message
}