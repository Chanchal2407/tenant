[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    $SiteUrl,
    [Parameter(Mandatory=$true)]
    $ALAdminSiteUrl,
    [Parameter(Mandatory=$true)]
    $AdminPortalTemplatePath,
    [Parameter(Mandatory=$true)]
    $OrganizationTemplatePath,
    [Parameter(Mandatory=$true)]
    $Environment
)

$listName = "Portal site prefix";
#Build connections
$portalLandingConnection =  Connect-PnPOnline -Url  $SiteUrl -ReturnConnection
$adminPortalConnection =  Connect-PnPOnline -Url  $ALAdminSiteUrl -ReturnConnection

# Connect to Admin site
#Connect-PnPOnline -Url  $ALAdminSiteUrl

#Apply Admin portal Site Prefix list template
Apply-PnPProvisioningTemplate -Path $AdminPortalTemplatePath -Handlers Lists -Connection $adminPortalConnection
Write-Host "Applied Admin portal template to create Site Prefix list"
#Update items in "Portal site prefix" list
$list = Get-PnPList -Identity $listName -ErrorAction SilentlyContinue -Connection $adminPortalConnection 
if($null -ne $list) {
    Add-PnPListItem -List $listName -Values @{"Title"="About Alfa Laval";"Prefix"="aboutalfalaval"}
    Add-PnPListItem -List $listName -Values @{"Title"="Key Initiatives and Global Programs";"Prefix"="globalprogram"}
    Add-PnPListItem -List $listName -Values @{"Title"="Other";"Prefix"="portal"}
    Add-PnPListItem -List $listName -Values @{"Title"="Organization";"Prefix"="organization"}
}

Write-Host "Added Site prefix list entries..."

# Upload OrganizationTemplate to Portal landing site site assets under "Templates" folder
Add-PnPFile -Path $OrganizationTemplatePath -Folder "/SiteAssets/Templates" -Connection $portalLandingConnection

Write-Host "Uploaded Organization Template xml successfully..."
# Add Entry in portal landing site for Choice field
$field = Get-PnPField -Identity "SiteType" -Connection $portalLandingConnection
[xml]$schemaXml = $field.SchemaXml
$Organization = $schemaXml.CreateElement("CHOICE")
$Organization.InnerText = "Organization"
$schemaXml.Field.CHOICES.AppendChild($Organization)
Set-PnPField -Identity "SiteType" -Values @{SchemaXml=$schemaXml.OuterXml} -UpdateExistingLists -Connection $portalLandingConnection
Write-Host "Updated Site Type Choice column with additional choice for Organization..."
Write-Host "Organization Template Site level artefacts are configured. Continue with Flow package updates and deployment of CreatePortalSite Azure Functions..." -BackgroundColor Green

Disconnect-PnPOnline
