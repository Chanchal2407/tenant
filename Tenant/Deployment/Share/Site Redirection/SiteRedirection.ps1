try {
    # Reading setting file
	$Config = (Get-Content "SiteConfig.json") | Out-String | ConvertFrom-Json
    Write-Host "Creating mapping list at $($Config.SiteURL)"
    Connect-PnPOnline -WarningAction Ignore -Url $Config.SiteURL -ClientId $Config.ClientID -ClientSecret $Config.ClientSecret
    $list = New-PnPList -Title "AboutMe Redirection Mapping" -Template GenericList -EnableVersioning
    Add-PnPField -List $list -Type Text -DisplayName "Redirect Link" -InternalName "RedirectLink" -AddToDefaultView
    Add-PnPListItem -List $list -Values @{"Title" = "India"}
    Add-PnPListItem -List $list -Values @{"Title" = "China"}
    Add-PnPListItem -List $list -Values @{"Title" = "Denmark"}
    Add-PnPListItem -List $list -Values @{"Title" = "Sweden"}
    Add-PnPListItem -List $list -Values @{"Title" = "United States of America"}
}
catch {
	Write-Host "EXCEPTION HAPPENED IN THE SCRIPT: $($_.InvocationInfo.ScriptName)" -ForegroundColor Red
	Write-Host "EXCEPTION HAPPENED IN THE LINE: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
	Read-Host $_.Exception.Message
}