try {
    # Reading setting file
    $Config = (Get-Content "SiteConfig.json") | Out-String | ConvertFrom-Json
    # Connect to CDN site mentioned in SiteConfig.json
    Connect-PnPOnline -Url $Config.OrganizationSettings.CDNSiteUrl
    
    # Add folders in Site Assets. If already present silenty continue
    $localShareFolder = "Share" + $config.OrganizationSettings.environment.toString().toUpper()
    Add-PnPFolder -Name "Share" -Folder "SiteAssets" -ErrorAction SilentlyContinue
    Add-PnPFolder -Name $localShareFolder -Folder "SiteAssets/Share" -ErrorAction SilentlyContinue
    Add-PnPFolder -Name "Common" -Folder $("SiteAssets/Share/"+$localShareFolder) -ErrorAction SilentlyContinue
    Add-PnPFolder -Name "News Template" -Folder $("SiteAssets/Share/"+$localShareFolder) -ErrorAction SilentlyContinue 
    Write-Host "Share related CDN folders created successfully" -ForegroundColor Green
    Add-PnPFile -Path AL_News_Empty.PNG -Folder $("SiteAssets/Share/"+$localShareFolder+"/News Template") -ErrorAction SilentlyContinue
    Write-Host "Uploaded AL_News_Empty.PNG successfully" -ForegroundColor Green

    Disconnect-PnPOnline
}
catch {
    Write-Host "EXCEPTION HAPPENED IN THE SCRIPT: $($_.InvocationInfo.ScriptName)" -ForegroundColor Red $_.Exception
}