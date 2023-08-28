# Pre-requisites:
# Install the following packages to run this script:
# SharePointPnPPowerShellOnline.msi : https://github.com/SharePoint/PnP-PowerShell/releases
# SharePoint Online Management Shell : https://www.microsoft.com/en-us/download/details.aspx?id=35588
# Add account admin to Termstore admins

try {
	# Reading setting file
	$Config = (Get-Content "ToolSitesConfig.json") | Out-String | ConvertFrom-Json
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
	& ".\CreateToolSiteLanding.ps1"

	# Add site design for tool sites
	& ".\AddToolSiteDesign.ps1"

	# Attach global navigation
	& ".\AttachGlobalNavi.ps1"

	Write-host "!!!!!!!!!!!!!!!" -f Yellow
	Write-host "!!!" -f Yellow
	Write-host "!!! Remember to add webparts to the landing page (like Tool Site Directory) - look for script in TFS\..\Deployment\Scripts\Sprint 13\AddWebPartToPage.ps1" -f Yellow
	Write-host "!!!" -f Yellow
	Write-host "!!!!!!!!!!!!!!!" -f Yellow
	
	Write-Host "--DONE--" -ForegroundColor Green
}
catch {
	Write-Host "EXCEPTION HAPPENED IN THE SCRIPT: $($_.InvocationInfo.ScriptName)" -ForegroundColor Red
	Write-Host "EXCEPTION HAPPENED IN THE LINE: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
	Read-Host $_.Exception.Message
}