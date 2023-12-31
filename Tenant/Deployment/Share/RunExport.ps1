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

    Connect-PnPOnline -Url $($Config.organizationSettings.tenantUrl + $Config.SiteCollections.RootSite.SiteUrl) -Credentials $O365Credential -ErrorAction Stop

    Get-PnPProvisioningTemplate -Out "Export.xml" -IncludeNativePublishingFiles -PersistBrandingFiles -PersistPublishingFiles -IncludeSiteGroups -IncludeSearchConfiguration -IncludeAllTermGroups -IncludeSiteCollectionTermGroup -IncludeTermGroupsSecurity

}
catch {
	Write-Host "EXCEPTION HAPPENED IN THE SCRIPT: $($_.InvocationInfo.ScriptName)" -ForegroundColor Red
	Write-Host "EXCEPTION HAPPENED IN THE LINE: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
	Write-Error $_.Exception.Message
}