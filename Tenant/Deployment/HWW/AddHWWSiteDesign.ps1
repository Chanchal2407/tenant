
try {
	# Reading setting file
	$Config = (Get-Content "HWWSitesConfig.json") | Out-String | ConvertFrom-Json
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
        
        # Language settings
        $scriptJson = Get-Content "script-languageSettings.json" -Raw
        $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "Global Language Setting UK" }
        if ($script -ne $null) {
            $languageScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
            $languageScript = $script
        } else {
            $languageScript = Add-PnPSiteScript -Title "Global Language Setting UK" -Description "Alfalaval language setting UK" -Content $scriptJson
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

        # Associate site with HUB    
        $scriptJson = Get-Content $("HWWSiteDesign\" + $Config.OrganizationSettings.environment + "\hww-script-joinToHub.json") -Raw
        $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "$ALEnvPrefix Join to HWWSite Hub" }
        if ($script -ne $null) {
            $joinHubscript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
            $joinHubscript = $script
        } else {
            $joinHubscript = Add-PnPSiteScript -Title "$ALEnvPrefix Join to HWWSite Hub" -Description "Join site to HWWSite Hub" -Content $scriptJson
        }
                    
        # Start : Feature - 146988 - How We Work - Included below code to add page footer extension to newly created hww sites           
        # Add Page Footer
        $scriptJson = Get-Content $("HWWSiteDesign\" + $Config.OrganizationSettings.environment + "\hww-script-pageFooterExtension.json") -Raw
        $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "$ALEnvPrefix HWW Page Footer Extension" }
        if ($script -ne $null) {
            $addFooterScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
            $addFooterScript = $script
        } else {
            $addFooterScript = Add-PnPSiteScript -Title "$ALEnvPrefix HWW Page Footer Extension" -Description "HWW Page Footer Extension" -Content $scriptJson
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

        # Apply Clarity for Prod, This is already deployed for PROD version
        if ($Config.OrganizationSettings.environment -eq "PROD")
        {
            # Add Clarity
            $scriptJson = Get-Content $("HWWSiteDesign\" + $Config.OrganizationSettings.environment + "\hww-script-clarityExtension.json") -Raw
            $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "$ALEnvPrefix HWW Microsoft Clarity Extension" }
            if ($script -ne $null) {
                $addClarityScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
                $addClarityScript = $script
            } else {
                $addClarityScript = Add-PnPSiteScript -Title "$ALEnvPrefix HWW Microsoft Clarity Extension" -Description "Add HWW Microsoft Clarity" -Content $scriptJson
            }
        }

        # End 

    Write-Host "OK" -ForegroundColor Green


    # ADD SITE DESIGN
    $newDesignTitle = "$ALEnvPrefix design - How we work site"
    Write-Host "Adding '$newDesignTitle'... " -NoNewline
        $existingDesign = Get-PnPSiteDesign | Where-Object { $_.Title -eq $newDesignTitle }
        if ($existingDesign -ne $null) {
            # Apply Clarity for Prod, This is already deployed for PROD version
            if ($Config.OrganizationSettings.environment -eq "PROD")
            {
                $sitedesign = Set-PnPSiteDesign -Identity $existingDesign.Id -SiteScriptIds $themeScript.ID,$languageScript.ID,$brandingScript.ID,$addGlobalTopNavScript.ID,$joinHubscript.ID,$addFooterScript.ID,$sitePagesScript.ID,$addCriticalInfoScript.ID,$addClarityScript.ID
            }
            else{
                $sitedesign = Set-PnPSiteDesign -Identity $existingDesign.Id -SiteScriptIds $themeScript.ID,$languageScript.ID,$brandingScript.ID,$addGlobalTopNavScript.ID,$joinHubscript.ID,$addFooterScript.ID,$sitePagesScript.ID,$addCriticalInfoScript.ID
            }
        } else {
            # Apply Clarity for Prod, This is already deployed for PROD version
            if ($Config.OrganizationSettings.environment -eq "PROD")
            {    
                $sitedesign = Add-PnPSiteDesign -Title $newDesignTitle -WebTemplate "68" -SiteScriptIds $themeScript.ID,$languageScript.ID,$brandingScript.ID,$addGlobalTopNavScript.ID,$joinHubscript.ID,$addFooterScript.ID,$sitePagesScript.ID,$addCriticalInfoScript.ID,$addClarityScript.ID -Description "AlfaLaval How We Work site design"
            }else{
                $sitedesign = Add-PnPSiteDesign -Title $newDesignTitle -WebTemplate "68" -SiteScriptIds $themeScript.ID,$languageScript.ID,$brandingScript.ID,$addGlobalTopNavScript.ID,$joinHubscript.ID,$addFooterScript.ID,$sitePagesScript.ID,$addCriticalInfoScript.ID -Description "AlfaLaval How We Work site design"
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
