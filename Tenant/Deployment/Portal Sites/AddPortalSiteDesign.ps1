
try {
	# Reading setting file
	$Config = (Get-Content "PortalSitesConfig.json") | Out-String | ConvertFrom-Json
	if ($Config.OrganizationSettings.askCredentials)
	{
		$O365Credential = Get-Credential
	}
	else
	{
		$securePassword = ConvertTo-SecureString $Config.organizationsettings.password -AsPlainText -Force
		$O365Credential = New-Object System.Management.Automation.PsCredential($Config.organizationsettings.username, $securePassword)
	}

	#Define proper environment
    Write-Host "Environment: " $Config.OrganizationSettings.environment	-ForegroundColor Yellow

    # Generate Alfalaval title depending on env
    $ALEnvPrefix = "AlfaLaval"; #default for prod
    if ($Config.OrganizationSettings.environment -ne "PROD")
    {
        $ALEnvPrefix = $Config.OrganizationSettings.environment.ToUpper() + " AlfaLaval";
    }
    
    # Authenticaiton
    Connect-PnPOnline -Url $Config.organizationsettings.sharePointAdminUrl -Credentials $O365Credential -ErrorAction Stop

    # ADD SITE SCRIPTS
    Write-Host "Adding site scripts... " -NoNewline

        # ---
        # Global site scripts
        # ---

        # AlfaLaval theme
        $scriptJson = Get-Content "..\GlobalSiteScripts\global-script-applyAlfaTheme.json" -Raw
        $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "Apply AlfaLaval theme" }
        if ($script -ne $null) {
            $themeScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
            $themeScript = $script
        } else {
            $themeScript = Add-PnPSiteScript -Title "Apply AlfaLaval theme" -Description "Apply AlfaLaval theme" -Content $scriptJson
        }
        
#        # External Sharing
#        $scriptJson = Get-Content "..\GlobalSiteScripts\global-script-externalSharing.json" -Raw
#        $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "Global External Sharing" }
#        if ($script -ne $null) {
#            $sharingScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
#            $sharingScript = $script
#        } else {
#            $sharingScript = Add-PnPSiteScript -Title "Global External Sharing" -Description "Set external sharing to disabled" -Content $scriptJson
#        }

        # Language settings
        $scriptJson = Get-Content "..\GlobalSiteScripts\global-script-languageSettings.json" -Raw
        $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "Global Language Setting" }
        if ($script -ne $null) {
            $languageScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
            $languageScript = $script
        } else {
            $languageScript = Add-PnPSiteScript -Title "Global Language Setting" -Description "Alfalaval language setting" -Content $scriptJson
        }

        # Branding settings
        $scriptJson = Get-Content "..\GlobalSiteScripts\global-script-branding.json" -Raw
        $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "Global Branding" }
        if ($script -ne $null) {
            $brandingScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
            $brandingScript = $script
        } else {
            $brandingScript = Add-PnPSiteScript -Title "Global Branding" -Description "Alfalaval branding" -Content $scriptJson
        }
        
        # ---
        # Env depending site scripts
        # ---
        
        # Add Global navigation (Common for local and tool sites)
        $scriptJson = Get-Content $("..\GlobalSiteScripts\" + $Config.OrganizationSettings.environment + "\global-script-globalExtension.json") -Raw
        $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "$ALEnvPrefix Global Navigation Extension" }
        if ($script -ne $null) {
            $addGlobalTopNavScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
            $addGlobalTopNavScript = $script
        } else {
            $addGlobalTopNavScript = Add-PnPSiteScript -Title "$ALEnvPrefix Global Navigation Extension" -Description "Add Global Top Navigation" -Content $scriptJson
        }

        # Add Critical Info alert (Common for local and tool sites)
        $scriptJson = Get-Content $("..\GlobalSiteScripts\" + $Config.OrganizationSettings.environment + "\global-script-criticalinfoExtension.json") -Raw
        $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "$ALEnvPrefix Critical Information Extension" }
        if ($script -ne $null) {
            $addCriticalInfoScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
            $addCriticalInfoScript = $script
        } else {
            $addCriticalInfoScript = Add-PnPSiteScript -Title "$ALEnvPrefix Critical Information Extension" -Description "Add Critical Information Alert" -Content $scriptJson
        }

        # Add CLC notification bar
        $scriptJson = Get-Content $("..\GlobalSiteScripts\" + $Config.OrganizationSettings.environment + "\global-script-clcExtension.json") -Raw
        $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "$ALEnvPrefix Share Portal CLC Extensions" }
        if ($script -ne $null) {
            $addCLCNotifyScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
            $addCLCNotifyScript = $script
        } else {
            $addCLCNotifyScript = Add-PnPSiteScript -Title "$ALEnvPrefix Share Portal CLC Extensions" -Description "Add CLC notification bar" -Content $scriptJson
        }
                    
        # Add Page Footer
        $scriptJson = Get-Content $("PortalSiteDesign\" + $Config.OrganizationSettings.environment + "\portalsite-script-pageFooterExtension.json") -Raw
        $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "$ALEnvPrefix PortalSite Page Footer Extension" }
        if ($script -ne $null) {
            $addFooterScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
            $addFooterScript = $script
        } else {
            $addFooterScript = Add-PnPSiteScript -Title "$ALEnvPrefix PortalSite Page Footer Extension" -Description "PortalSite Page Footer Extension" -Content $scriptJson
        }

        # Add PageOwner and PageEditor columns to Site Pages
        $scriptJson = Get-Content "..\GlobalSiteScripts\global-script-SitePagesOwnerEditor.json" -Raw
        $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "Site Pages Owner and Editor" }
        if ($script -ne $null) {
            $sitePagesScript = Set-PnPSiteScript -Identity $script[0].Id -Content $scriptJson
            $sitePagesScript = $script[0]
        } else {
            $sitePagesScript = Add-PnPSiteScript -Title "Site Pages Owner and Editor" -Description "Update Site Pages with Owner and Editor fields" -Content $scriptJson
        }

        # Apply Clarity for Prod, This is already deployed for UAT and PROD version
        if (($Config.OrganizationSettings.environment -eq "PROD") -or ($Config.OrganizationSettings.environment -eq "UAT"))
        {
            # Add Clarity
            $scriptJson = Get-Content $("PortalSiteDesign\" + $Config.OrganizationSettings.environment + "\portalsite-script-clarityExtension.json") -Raw
            $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "$ALEnvPrefix PortalSite Microsoft Clarity Extension" }
            if ($script -ne $null) {
                $addClarityScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
                $addClarityScript = $script
            } else {
                $addClarityScript = Add-PnPSiteScript -Title "$ALEnvPrefix PortalSite Microsoft Clarity Extension" -Description "Add PortalSite Microsoft Clarity" -Content $scriptJson
            }
        }

    Write-Host "OK" -ForegroundColor Green


    # ADD SITE DESIGN
    $newDesignTitle = "$ALEnvPrefix design - Portal Team site"
    Write-Host "Adding '$newDesignTitle'... " -NoNewline
        $exisitngDesign = Get-PnPSiteDesign | Where-Object { $_.Title -eq $newDesignTitle }
        if ($exisitngDesign -ne $null) {
            # Apply Clarity for Prod, This is already deployed for UAT and PROD version
            if (($Config.OrganizationSettings.environment -eq "PROD") -or ($Config.OrganizationSettings.environment -eq "UAT"))
            {
                $sitedesign = Set-PnPSiteDesign -Identity $exisitngDesign.Id -SiteScriptIds $themeScript.ID,$languageScript.ID,$brandingScript.ID,$addGlobalTopNavScript.ID,$sitePagesScript.ID,$addFooterScript.ID,$addCLCNotifyScript.ID,$addCriticalInfoScript.ID,$addClarityScript.ID
            }
            else{
                $sitedesign = Set-PnPSiteDesign -Identity $exisitngDesign.Id -SiteScriptIds $themeScript.ID,$languageScript.ID,$brandingScript.ID,$addGlobalTopNavScript.ID,$sitePagesScript.ID,$addFooterScript.ID,$addCLCNotifyScript.ID,$addCriticalInfoScript.ID
            }
        } else {
            # Apply Clarity for Prod, This is already deployed for UAT and PROD version
            if (($Config.OrganizationSettings.environment -eq "PROD") -or ($Config.OrganizationSettings.environment -eq "UAT"))
            {
                $sitedesign = Add-PnPSiteDesign -Title $newDesignTitle -WebTemplate "64" -SiteScriptIds $themeScript.ID,$languageScript.ID,$brandingScript.ID,$addGlobalTopNavScript.ID,$sitePagesScript.ID,$addFooterScript.ID,$addCLCNotifyScript.ID,$addCriticalInfoScript.ID,$addClarityScript.ID -Description "AlfaLaval Portal Team site design"
            }
            else{
                $sitedesign = Add-PnPSiteDesign -Title $newDesignTitle -WebTemplate "64" -SiteScriptIds $themeScript.ID,$languageScript.ID,$brandingScript.ID,$addGlobalTopNavScript.ID,$sitePagesScript.ID,$addFooterScript.ID,$addCLCNotifyScript.ID,$addCriticalInfoScript.ID -Description "AlfaLaval Portal Team site design"
            }
        }
        if ($Config.OrganizationSettings.environment -ne "DEV")
        {
            Grant-PnPSiteDesignRights -Identity $sitedesign.Id -Principals "ShareOnline_Support_Admin" -Rights View
        }
    Write-Host "OK" -ForegroundColor Green

    $newDesignTitle = "$ALEnvPrefix design - Portal Com. site"
    Write-Host "Adding '$newDesignTitle'... " -NoNewline
        $exisitngDesign = Get-PnPSiteDesign | Where-Object { $_.Title -eq $newDesignTitle }
        if ($exisitngDesign -ne $null) {
            # Apply Clarity for Prod, This is already deployed for UAT and PROD version
            if (($Config.OrganizationSettings.environment -eq "PROD") -or ($Config.OrganizationSettings.environment -eq "UAT"))
            {
                $sitedesign = Set-PnPSiteDesign -Identity $exisitngDesign.Id -SiteScriptIds $themeScript.ID,$languageScript.ID,$brandingScript.ID,$addGlobalTopNavScript.ID,$sitePagesScript.ID,$addFooterScript.ID,$addCLCNotifyScript.ID,$addCriticalInfoScript.ID,$addClarityScript.ID
            }
            else{
                $sitedesign = Set-PnPSiteDesign -Identity $exisitngDesign.Id -SiteScriptIds $themeScript.ID,$languageScript.ID,$brandingScript.ID,$addGlobalTopNavScript.ID,$sitePagesScript.ID,$addFooterScript.ID,$addCLCNotifyScript.ID,$addCriticalInfoScript.ID
            }
        } else {
            # Apply Clarity for Prod, This is already deployed for UAT and PROD version
            if (($Config.OrganizationSettings.environment -eq "PROD") -or ($Config.OrganizationSettings.environment -eq "UAT"))
            {
                $sitedesign = Add-PnPSiteDesign -Title $newDesignTitle -WebTemplate "68" -SiteScriptIds $themeScript.ID,$languageScript.ID,$brandingScript.ID,$addGlobalTopNavScript.ID,$sitePagesScript.ID,$addFooterScript.ID,$addCLCNotifyScript.ID,$addCriticalInfoScript.ID,$addClarityScript.ID -Description "AlfaLaval Portal Communication site design" 
            }
            else{
                $sitedesign = Add-PnPSiteDesign -Title $newDesignTitle -WebTemplate "68" -SiteScriptIds $themeScript.ID,$languageScript.ID,$brandingScript.ID,$addGlobalTopNavScript.ID,$sitePagesScript.ID,$addFooterScript.ID,$addCLCNotifyScript.ID,$addCriticalInfoScript.ID -Description "AlfaLaval Portal Communication site design" 
            }
        }
        if ($Config.OrganizationSettings.environment -ne "DEV")
        {
            Grant-PnPSiteDesignRights -Identity $sitedesign.Id -Principals "ShareOnline_Support_Admin" -Rights View
        }
    Write-Host "OK" -ForegroundColor Green

    # disconnect
    Disconnect-PnPOnline

} catch {
	Write-Host "EXCEPTION HAPPENED IN THE SCRIPT: $($_.InvocationInfo.ScriptName)" -ForegroundColor Red
	Write-Host "EXCEPTION HAPPENED IN THE LINE: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
	Read-Host $_.Exception.Message
}
