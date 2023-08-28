#########################################################################
# This script enables Private CDN
# Dependency on SiteConfig.json to pick Admin url
#########################################################################

 # Reading setting file
 $Config = (Get-Content "SiteConfig.json") | Out-String | ConvertFrom-Json
 
 # Connect to SharePoint admin site url
 Connect-SPOService -Url $config.OrganizationSettings.sharePointAdminUrl

 # Set Private CDN
 Set-SPOTenantCdnEnabled -CdnType Private
 
 # Add Organization asset library with cdntype Private (Change this line once merged to SprintDev to read from Siteconfig.json). Also mention ThumbNailUrl for this.
 Add-SPOOrgAssetsLibrary -LibraryUrl https://alfalavalonline.sharepoint.com/sites/OrganizationAssets/Internal%20Organization%20Library -CdnType Private

 #Disconnect the service
 Disconnect-SPOService
