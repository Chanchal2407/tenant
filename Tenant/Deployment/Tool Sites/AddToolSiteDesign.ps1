# Generate Alfalaval title depending on env
$ALEnvPrefix = "AlfaLaval"; #default for prod
if ($Config.OrganizationSettings.environment -ne "PROD")
{
    $ALEnvPrefix = $Config.OrganizationSettings.environment.ToUpper() + " AlfaLaval";
}

# promt for hub site update
Connect-PnPOnline -Url $($Config.organizationSettings.tenantUrl + $Config.SiteCollections.RootSite.SiteUrl) -Credentials $O365Credential -ErrorAction Stop
$site = Get-PnPSite -Includes Id
$tmp = Read-Host "Please update site script 'toolsite-script-joinToHub.json' with Hub id='$($site.Id)' and press any key to continue"
Disconnect-PnPOnline


# Authenticaiton
Connect-PnPOnline -Url $Config.organizationsettings.sharePointAdminUrl -Credentials $O365Credential -ErrorAction Stop


# ADD SITE SCRIPTS
Write-Host "Adding site scripts... " -NoNewline

    # ---
    # Global site scripts
    # ---

    # External Sharing
    $scriptJson = Get-Content "..\GlobalSiteScripts\global-script-externalSharing.json" -Raw
    $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "Global External Sharing" }
    if ($script -ne $null) {
        $sharingScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
        $sharingScript = $script
    } else {
        $sharingScript = Add-PnPSiteScript -Title "Global External Sharing" -Description "Set external sharing to disabled" -Content $scriptJson
    }

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
        
    # Associate site with HUB    
    $scriptJson = Get-Content $("ToolSiteDesign\" + $Config.OrganizationSettings.environment + "\toolsite-script-joinToHub.json") -Raw
    $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "$ALEnvPrefix Join to ToolSite Hub" }
    if ($script -ne $null) {
        $joinHubscript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
        $joinHubscript = $script
    } else {
        $joinHubscript = Add-PnPSiteScript -Title "$ALEnvPrefix Join to ToolSite Hub" -Description "Join site to ToolSite Hub" -Content $scriptJson
    }
        
    # Navigation
    $scriptJson = Get-Content $("ToolSiteDesign\" + $Config.OrganizationSettings.environment + "\toolsite-script-navi.json") -Raw
    $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "$ALEnvPrefix ToolSite navigation" }
    if ($script -ne $null) {
        $addNavScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
        $addNavScript = $script
    } else {
        $addNavScript = Add-PnPSiteScript -Title "$ALEnvPrefix ToolSite navigation" -Description "Add ToolSite navigation" -Content $scriptJson
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

    # Add Footer
    $scriptJson = Get-Content $("ToolSiteDesign\" + $Config.OrganizationSettings.environment + "\toolsite-script-footerExtension.json") -Raw
    $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "$ALEnvPrefix ToolSite Footer Extension" }
    if ($script -ne $null) {
        $addFooterScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
        $addFooterScript = $script
    } else {
        $addFooterScript = Add-PnPSiteScript -Title "$ALEnvPrefix ToolSite Footer Extension" -Description "Add ToolSite Footer" -Content $scriptJson
    }

    # Apply Clarity for Prod, This is already deployed for UAT and PROD version
    if (($Config.OrganizationSettings.environment -eq "PROD") -or ($Config.OrganizationSettings.environment -eq "UAT"))
    {
        # Add Clarity
        $scriptJson = Get-Content $("ToolSiteDesign\" + $Config.OrganizationSettings.environment + "\toolsite-script-clarityExtension.json") -Raw
        $script = Get-PnPSiteScript | Where-Object { $_.Title -eq "$ALEnvPrefix ToolSite Microsoft Clarity Extension" }
        if ($script -ne $null) {
            $addClarityScript = Set-PnPSiteScript -Identity $script.Id -Content $scriptJson
            $addClarityScript = $script
        } else {
            $addClarityScript = Add-PnPSiteScript -Title "$ALEnvPrefix ToolSite Microsoft Clarity Extension" -Description "Add ToolSite Microsoft Clarity" -Content $scriptJson
        }
    }
    
Write-Host "OK" -ForegroundColor Green


# ADD SITE DESIGN
Write-Host "Adding Tool Site design... " -NoNewline
    $exisitngDesign = Get-PnPSiteDesign | Where-Object { $_.Title -eq "$ALEnvPrefix design - Tool site" }
    if ($exisitngDesign -ne $null) {
        # Apply Clarity for Prod, This is already deployed for UAT and PROD version
        if (($Config.OrganizationSettings.environment -eq "PROD") -or ($Config.OrganizationSettings.environment -eq "UAT"))
        {
            $sitedesign = Set-PnPSiteDesign -Identity $exisitngDesign.Id -SiteScriptIds $sharingScript.ID,$languageScript.ID,$joinHubscript.ID,$addGlobalTopNavScript.ID,$sitePagesScript.ID,$addFooterScript.ID,$addCLCNotifyScript.ID,$addNavScript.ID,$brandingScript.ID,$addCriticalInfoScript.ID,$addClarityScript.ID
        }
        else{
            $sitedesign = Set-PnPSiteDesign -Identity $exisitngDesign.Id -SiteScriptIds $sharingScript.ID,$languageScript.ID,$joinHubscript.ID,$addGlobalTopNavScript.ID,$sitePagesScript.ID,$addFooterScript.ID,$addCLCNotifyScript.ID,$addNavScript.ID,$brandingScript.ID,$addCriticalInfoScript.ID
        }
    } else {
        # Apply Clarity for Prod, This is already deployed for UAT and PROD version
        if (($Config.OrganizationSettings.environment -eq "PROD") -or ($Config.OrganizationSettings.environment -eq "UAT"))
        {
            $sitedesign = Add-PnPSiteDesign -Title "$ALEnvPrefix design - Tool site" -WebTemplate "68" -SiteScriptIds $sharingScript.ID,$languageScript.ID,$joinHubscript.ID,$addGlobalTopNavScript.ID,$sitePagesScript.ID,$addFooterScript.ID,$addCLCNotifyScript.ID,$addNavScript.ID,$brandingScript.ID,$addCriticalInfoScript.ID,$addClarityScript.ID -Description "AlfaLaval Tool site design"
        }
        else{
            $sitedesign = Add-PnPSiteDesign -Title "$ALEnvPrefix design - Tool site" -WebTemplate "68" -SiteScriptIds $sharingScript.ID,$languageScript.ID,$joinHubscript.ID,$addGlobalTopNavScript.ID,$sitePagesScript.ID,$addFooterScript.ID,$addCLCNotifyScript.ID,$addNavScript.ID,$brandingScript.ID,$addCriticalInfoScript.ID -Description "AlfaLaval Tool site design"
        }
    }
    if ($Config.OrganizationSettings.environment -ne "DEV")
    {
        Grant-PnPSiteDesignRights -Identity $sitedesign.Id -Principals "Share.Collaboration@alfalavalonline.onmicrosoft.com" -Rights View
    }
Write-Host "OK" -ForegroundColor Green


Disconnect-PnPOnline
