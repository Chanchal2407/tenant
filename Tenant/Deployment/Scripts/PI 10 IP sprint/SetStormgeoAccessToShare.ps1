
Param(
    [Parameter(Mandatory=$true)]
    [string]$domain,
    [Parameter(Mandatory=$true)]
    [string]$adminSiteUrl,
    [Parameter(Mandatory=$true)]
    [string]$csvPathIncluded,
    [Parameter(Mandatory=$true)]
    [string]$csvFilePath
)

#Local variables (DONT CHECKIN as it contains sensitive information)
$clientID = "ad1a97cf-acbc-48c0-a55f-b69d7f4226b2"
$certificatePassword = ConvertTo-SecureString "***" -AsPlainText -Force
$appAdTenant = "alfalavalonline.onmicrosoft.com"

if("Yes" -eq $csvPathIncluded) {    
    $csvFileInputs = Import-Csv $csvFilePath -Delimiter ","
    if($null -ne $csvFileInputs) {
        $csvFileInputs | %{
            $siteUrl = $_.URL;
            echo "Connecting to $($siteUrl)"
            Connect-PnPOnline -ClientId $clientID -CertificatePath "**" -CertificatePassword $certificatePassword -Tenant $appAdTenant -Url $siteUrl 
            $web = Get-PnPWeb -Includes AssociatedVisitorGroup
            #Enable SharePoint site Domain access to StoremGeo only
            Set-PnPTenantSite -Url $siteUrl -SharingCapability ExternalUserSharingOnly -SharingAllowedDomainList $domain -SharingDomainRestrictionMode AllowList
            echo "Added StoremGeo domain as allowed guest"
            # ADD StormGeo_Manual to respective site associated Visitors group
            Add-PnPUserToGroup -LoginName "c:0t.c|tenant|5ba078f9-e9c6-414f-ab6d-acb34ad750aa" -Identity $web.AssociatedVisitorGroup.Title
            echo "Added StormGeo_Manual as visitors"
            Disconnect-PnPOnline
        }
    }
}

else {
#Connect to Admin portal url
Connect-PnPOnline -ClientId $clientID -CertificatePath "**" -CertificatePassword $certificatePassword -Tenant $appAdTenant -Url $adminSiteUrl

$siteItems = Get-PnPListItem -List "CLC Inclusion List" -Fields "ALFA_ADM_SiteUrl"
if($null -ne $siteItems) {
    $siteItems | %{
        $siteUrl = $_["ALFA_ADM_SiteUrl"].Url;
        echo "Connecting to $($siteUrl)"
        if($siteUrl -like "*LocalSite-*" -or $site -like "*ToolSite-*"){
            echo "Seperate csv file will be used for this hub site and connected sites"
        }else{
            Connect-PnPOnline -ClientId $clientID -CertificatePath "**" -CertificatePassword $certificatePassword -Tenant $appAdTenant -Url $siteUrl 
            $web = Get-PnPWeb -Includes AssociatedVisitorGroup
            #Enable SharePoint site Domain access to StoremGeo only
             Set-PnPTenantSite -Url $siteUrl -SharingCapability ExternalUserSharingOnly -SharingAllowedDomainList $domain -SharingDomainRestrictionMode AllowList
             echo "Added StoremGeo domain as allowed guest"
            # ADD StormGeo_Manual to respective site associated Visitors group
            Add-PnPUserToGroup -LoginName "c:0t.c|tenant|5ba078f9-e9c6-414f-ab6d-acb34ad750aa" -Identity $web.AssociatedVisitorGroup.Title
            echo "Added StormGeo_Manual as visitors"
  
            Disconnect-PnPOnline
     }
    }
 }

}