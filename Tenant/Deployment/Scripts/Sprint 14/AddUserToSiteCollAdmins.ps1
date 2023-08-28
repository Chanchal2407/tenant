#
#    Alfa Laval
#    Task 5769 : Script to update all existing PROD Local sites with "ShareOnine_Support_Admin" group
#

$urls = @("https://contoso.sharepoint.com/sites/colaborationSite1/","https://contoso.sharepoint.com/sites/colaborationSite2/")

foreach($url in $urls)
{
    $user = "admin@contoso.onmicrosoft.com"
    $pssw = 'password' | ConvertTo-SecureString -asPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
    Connect-PnPOnline -Url $url –Credentials $cred

    Add-PnPSiteCollectionAdmin -Owners "user@contoso.sharepoint.com"

    Disconnect-PnPOnline
}

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "