try {
    # Reading setting file
	$Config = (Get-Content "SiteConfig.json") | Out-String | ConvertFrom-Json

    Write-Host "Creating local news site $($Config.NewsSiteURL)"
    Connect-PnPOnline -WarningAction Ignore -Url $Config.SharePointAdminUrl -ClientId $Config.ClientID -ClientSecret $Config.ClientSecret
    try {$RootSite = Get-PnPTenantSite -Url $Config.NewsSiteURL -ErrorAction SilentlyContinue} catch {$RootSite = $null}
    if ($RootSite -ne $null)
    {
        Write-Host "news site already exists."
        #exit;
    }
    if ($RootSite -eq $null)
    {
        $creationResult = New-PnPSite -Type CommunicationSite -Title $Config.NewsSiteTitle -Url $Config.NewsSiteURL -Owner $Config.SiteOwnerEmail -Wait
    }
    try {$RootSite = Get-PnPTenantSite -Url $Config.NewsSiteURL -ErrorAction SilentlyContinue} catch {$RootSite = $null}
    if ($RootSite -ne $null)
    {
        Write-Host "Site created successfully."
        Disconnect-PnPOnline
        Write-Host "Applying template."
        Connect-PnPOnline -WarningAction Ignore -Url $Config.NewsSiteURL -ClientId $Config.ClientID -ClientSecret $Config.ClientSecret
        Invoke-PnPSiteTemplate -Path $Config.TemplateURL
        Write-Host "Template applied successfully."
        Write-Host "Enabling page scheduling."
        Enable-PnPPageScheduling
        Write-Host "Adding global navigation extension"
        Add-PnPCustomAction -ClientSideComponentId $Config.Extensions.GlobalNavigation.Id -Name "ShareNavigationExtension" -Title "Share Navigation Extension" -Location ClientSideExtension.ApplicationCustomizer -Scope Site -ClientSideComponentProperties "{'TopMenuTermSet':'$($Config.Extensions.GlobalNavigation.Param)'}"
        Write-Host "Adding Share Critical Information Extension"
        Add-PnPCustomAction -ClientSideComponentId $Config.Extensions.ShareCriticalInformationExtension.Id -Name "ShareCriticalInformationExtension" -Title "Share Critical Information Extension" -Location ClientSideExtension.ApplicationCustomizer -Scope Site -ClientSideComponentProperties "{'AlertSiteUrl':'$($Config.Extensions.ShareCriticalInformationExtension.Param)'}"
        Disconnect-PnPOnline
        Write-Host "Process completed successfully"
    }
    if ($RootSite -eq $null)
    {
        Write-Host "Error creating news site."
    }
}
catch {
	Write-Host "EXCEPTION HAPPENED IN THE SCRIPT: $($_.InvocationInfo.ScriptName)" -ForegroundColor Red
	Write-Host "EXCEPTION HAPPENED IN THE LINE: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
	Read-Host $_.Exception.Message
}