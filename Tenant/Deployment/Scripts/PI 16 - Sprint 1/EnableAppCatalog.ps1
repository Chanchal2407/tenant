param(
    [switch]$Force = $false
)
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Write-Output $PSScriptRoot
$clientID = $null
$certificatePassword = $null
$bas64Encoded = $null

$appCert = Get-AutomationCertificate –Name "AzureADAPPAuth"

if ($null -eq $certificatePassword) {
    $certificatePassword = Get-AutomationPSCredential –Name 'AzureAppCertPassword'
}

Write-Output "Starting..." 
if ($null -eq $bas64Encoded) {
    # Export the certificate and convert into base 64 string
    $bas64Encoded = [System.Convert]::ToBase64String($appCert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $certificatePassword.Password))
}



if ($null -eq $clientId) {
    $clientId = Get-AutomationVariable –Name 'AppClientId'
}


if ($null -eq $certificatePassword) {
    $certificatePassword = Get-AutomationPSCredential –Name 'AzureAppCertPassword'
}


$appAdTenant = "alfalavalonline.onmicrosoft.com"
$AdminUrl ="https://alfalavalonline-admin.sharepoint.com"
$SiteUrl = "https://alfalavalonline.sharepoint.com/sites/PROMIS-hub"
#$SiteUrl = "https://alfalavalonline.sharepoint.com/sites/UAT-Collaboration-AzureAutomationJobTest"

Connect-PnPOnline -ClientId $clientId -CertificateBase64Encoded $bas64Encoded `
                    -CertificatePassword $certificatePassword.Password `
                    -Url $SiteUrl -Tenant $appAdTenant

Write-Host "test"


$startdate = [DateTime]::UtcNow.AddMinutes(-60).ToString("yyyy\-MM\-ddTHH\:mm\:ssZ")
$enddate = [DateTime]::UtcNow.ToString("yyyy\-MM\-ddTHH\:mm\:ssZ")

$recentlyUpdatedCaml = @"
<View Scope=`"RecursiveAll`">
  <Query>
      <Where>
      <And>
           <Gt>
              <FieldRef Name='Modified' />
              <Value IncludeTimeValue='True' Type='DateTime' StorageTZ='TRUE'>$startdate</Value>
          </Gt>
          <Lt>
              <FieldRef Name='Modified' />
              <Value IncludeTimeValue='True' Type='DateTime' StorageTZ='TRUE'>$enddate</Value>
          </Lt>
          </And>
           </Where>
          </Query>     
</View>
"@

Write-Output "Starting... 1" 
$listItemsNew = (Get-PnPListItem -List "PromisHubSites" -Query $recentlyUpdatedCaml).FieldValues

foreach($item in $listItemsNew)
{

Write-Output "Starting...2 " 

Disconnect-PnPOnline

Connect-PnPOnline -ClientId $clientId -CertificateBase64Encoded $bas64Encoded `
                    -CertificatePassword $certificatePassword.Password `
                    -Url $item.Title -Tenant $appAdTenant

#$list = $lists | Where-Object {$_Title -eq "Apps for SharePoint"}
Write-Output "Processing site: $item.Title"
$ifExist = Get-PnPSiteCollectionAppCatalog -CurrentSite
if($ifExist -eq $null)
{
    Add-PnPSiteCollectionAppCatalog -site $item.Title 
}
else{
    Write-Output "App catalog already exists"
}
}

Disconnect-PnPOnline