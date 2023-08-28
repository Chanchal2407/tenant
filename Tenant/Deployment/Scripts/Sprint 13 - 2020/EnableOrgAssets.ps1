#####################################################################################
#Written By : Gurudatt Bhat
#Purpose : This script enables Organization assets feature in the tenant

#####################################################################################
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$TenantAdminUrl,
    [Parameter(Mandatory=$true)]
    [string]$ThumbnailUrl,
    [Parameter(Mandatory=$true)]
    [string]$LibraryUrl,
    [Parameter(Mandatory=$true)]
    [string]$CdnType
)

# Connect to Admin endpoint url
Connect-SPOService -Url $TenantAdminUrl

# Check if Organization asset present already, if yes, show the message
$orgAssetLibrary = Get-SPOOrgAssetsLibrary  

if($orgAssetLibrary.Contains("No libraries have been specified as organization asset libraries")){
     #If not present, create one
   Add-SPOOrgAssetsLibrary -LibraryUrl $LibraryUrl -ThumbnailURL $ThumbnailUrl -OrgAssetType ImageDocumentLibrary
   Write-Output "Organization asset library is configured.It can take up to 24 hours to reflect.."
} else {
    Write-Output "Organization asset already exists in this tenant..."
    Write-Output $orgAssetLibrary 
}

Disconnect-SPOService