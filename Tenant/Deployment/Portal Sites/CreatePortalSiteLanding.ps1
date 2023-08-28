#Load SharePoint Online Prerequisits
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime") | Out-Null
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking | Out-Null

# Configuration
$TenantUrl = $Config.organizationsettings.tenantUrl
$SharePointAdminUrl = $Config.organizationsettings.sharePointAdminUrl
$SiteTitle = $Config.SiteCollections.RootSite.SiteTitle
$SiteUrl = $($TenantUrl + $Config.SiteCollections.RootSite.SiteUrl) 
$SiteTemplate = $Config.SiteCollections.RootSite.SiteTemplate 
# $HubSiteAdmins = $Config.SiteCollections.RootSite.HubSiteAdmins

# Connect
Connect-PnPOnline -Url $SharePointAdminUrl -Credentials $O365Credential -ErrorAction Stop

# SilentlyContinue is ignored - so using alternative approach not to log error in console
try {$ExisitngSite = Get-PnPTenantSite -Url $SiteUrl -ErrorAction SilentlyContinue} catch {$ExisitngSite = $null}

if ($ExisitngSite -ne $null)
{
    $deleteIfExists = Read-Host "Site collection with URL $SiteUrl already exists. Do you want to delete existing site and create new one? (Y/N)"

    if ($deleteIfExists.ToLower() -eq "y")
    {
        $toBeDeleted = Read-Host "Existing site collection will be deleted permanently. All subsites and data will be lost. Do you want to proceed? (Y/N)"

        if ($toBeDeleted.ToLower() -eq "y"){
        
        	Write-Host "Removing existing site.."

            Remove-PnPTenantSite -Url $SiteUrl -ErrorAction SilentlyContinue -SkipRecycleBin -Force

            $ExisitngSite = $null;

            Start-Sleep -s 30 # until all the processes are over
        }
    }
}

if ($ExisitngSite -eq $null){
    
    Write-Host "Creating new site collection with URL $SiteUrl  ..."

    New-PnPSite -Type CommunicationSite -Title $SiteTitle -Url $SiteUrl -SiteDesign $SiteTemplate -ErrorVariable errVar -ErrorAction Continue

    if ($errVar -ne $null) {
        $errJson = $errVar | ConvertFrom-Json
        if ($errJson.d.Create.SiteStatus -eq 1) {
            Write-Host "New-PnPSite: Please wait, you’ll get your site eventually."
            # wait
            $attemptCount = 10
            while($attemptCount -gt 0) {
                $site = Get-PnPTenantSite -Url $SiteUrl -ErrorAction SilentlyContinue
                if ($site.Status -eq "Active") {
                    Write-Host "New-PnPSite: Site was created successfully."
                    break;
                }
                $attemptCount--
                Write-Host "New-PnPSite: Site not ready. Remaining attempts: $attemptCount"
                Start-Sleep -s 20
            }

            # if site still not created
            if ($site.Status -ne "Active") {
                Write-Host "New-PnPSite: Waiting time is over. Site not ready."
                return;
            }
        } else {
            Write-Host "New-PnPSite: Fatal error. Site creation is failed."
            return;
        }
    } else {
        Write-Host "New-PnPSite: Site was created successfully."
    }
    
    Write-Host "Waiting till site is available ..."
    while ($true) {
        $site = Get-PnPTenantSite -Url $SiteUrl -ErrorAction SilentlyContinue
        if ($site.Status -eq "Active") {
            break;
        }
        Start-Sleep -s 20
    }

#    Write-Host "Registering as Hub site ..."
#    Register-PnPHubSite -Site $SiteUrl 
#		
#    [String[]]$myArray = $HubSiteAdmins -split ', ';
#
#    if ($myArray.Count -gt 0){
#        Write-Host "Adding administrators to the Hub site ..."
#        foreach($user in $myArray){
#            write-host "User: " $user
#            Grant-PnPHubSiteRights -Identity $SiteUrl -Principals $user  -Rights Join
#        }
#    }
	
	# Disocnnect from admin
	Disconnect-PnPOnline
    
    # Connect to the site
    Connect-PnPOnline -Url $SiteUrl -Credentials $O365Credential -ErrorAction Stop
    # Apply template
	Write-Host "Applying template..."
    Apply-PnPProvisioningTemplate -Path "PortalLandingTemplate.xml" -ErrorAction Stop
    
    # Apply AlfaLaval design
    $ALDesign = Get-PnPSiteDesign | Where-Object { $_.Title -eq "Alfalaval theme design" }
    if ($ALDesign -ne $null) {
        Write-Host "Applying Alfalaval theme design..."
        Invoke-PnPSiteDesign -Identity $ALDesign.Id -WebUrl $SiteUrl
    }

	Disconnect-PnPOnline
    
}


