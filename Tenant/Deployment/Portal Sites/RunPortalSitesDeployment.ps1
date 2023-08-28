# Pre-requisites:
# Install the following packages to run this script:
# SharePointPnPPowerShellOnline.msi : https://github.com/SharePoint/PnP-PowerShell/releases
# SharePoint Online Management Shell : https://www.microsoft.com/en-us/download/details.aspx?id=35588
# Add account admin to Termstore admins

try {
	# Reading setting file
	$Config = (Get-Content "PortalSitesConfig.json") | Out-String | ConvertFrom-Json
	if ($Config.OrganizationSettings.askCredentials)
	{
		$O365Credential = Get-Credential
	}
	else
	{
		$securePassword = ConvertTo-SecureString $Config.organizationsettings.password –AsPlainText –force
		$O365Credential = New-Object System.Management.Automation.PsCredential($Config.organizationsettings.username, $securePassword)
	}

	#Define proper environment
    Write-Host "Environment: " $Config.OrganizationSettings.environment	-ForegroundColor Yellow

	# Run script for site provisioning
	& ".\CreatePortalSiteLanding.ps1"

	# Add site design for tool sites
	& ".\AddPortalSiteDesign.ps1"

	# Attach global navigation
	& ".\AttachGlobalNavi.ps1"
	
	# Portal site Admin portal configuration - 6691
	& ".\Configure-OrganizationTemplate.ps1"
	
	Write-Host "--DONE--" -ForegroundColor Green
}
catch {
	Write-Host "EXCEPTION HAPPENED IN THE SCRIPT: $($_.InvocationInfo.ScriptName)" -ForegroundColor Red
	Write-Host "EXCEPTION HAPPENED IN THE LINE: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
	Read-Host $_.Exception.Message
}