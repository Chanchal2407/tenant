<#
Pre-Requisites : Run it in SharePoint online Management shell
          PnP.Powershell module (1.6.0 or above) must be loaded
TODO (08/07/2021): Automate complete Site catalog configuration. Create Feature for using Get/Apply-PnPTenantTemplate covering all Share main sites part of architecture
#>

#$currentDirLoc = Get-Location
#$oneLevelUp = Split-Path -Path $currentDirLoc -Parent
$scriptlocation = (Get-Location).Path
Write-Host "Pre-req: Make sure you are global tenant admin to run this script" -ForegroundColor Green
$envs = @("Production","UAT","QA","Dev")
$validVal = $true
Write-Host "Environment - (Production, UAT,Dev)"
$environment = Read-Host "Type Environment name to create a package"
for ($i = 0; $i -lt $envs.Count; $i++) {
            if($envs[$i] -eq $environment){
                $validVal = $true
                Copy-Item -Path "CollaborationSiteCatalogue-$environment.xml" -Destination "SiteCatalogue.xml"
                Convert-PnPFolderToSiteTemplate -Out "SiteCatalogue.pnp" -Folder ""
                Remove-Item -Path "SiteCatalogue.xml"
                Write-Host "SiteCatalogue.pnp has been created successfully"
                break
            }
            else{
                $validVal = $false
            }
}
if(!$validVal){
    Write-Host "Invalid environment."
}

$siteUrl = Read-Host "Enter Site collection Url"
$uri = [Uri]$siteUrl
$tenantUrl = $uri.Scheme + "://" + $uri.Host
$tenantAdminUrl = $tenantUrl.Replace(".sharepoint", "-admin.sharepoint")
Connect-PnPOnline -Url $siteUrl
Invoke-PnPSiteTemplate -Path SiteCatalogue.pnp -Handlers Fields,ContentTypes,Navigation,Pages
Write-Host "PnP artefacts applied to Collaboration landing site collection sucessfully" -ForegroundColor Green
# Set Collaboration sites as Landing page
Set-PnPHomePage -RootFolderRelativeUrl SitePages/CollaborationSites.aspx
Write-Host "New Home page set successfully" -ForegroundColor Green
#Create /Collaboration subsite if not present
$collaboratonUrl = Get-PnPSubWebs | %{ $_.ServerRelativeUrl }
if( $null -eq $collaboratonUrl ){
    # /Collaboration subsite not present, create one
    $web = New-PnPWeb -Title "Collaboration" -Url "collaboration" -Locale 1033 -Template "STS#0"
    Write-Host "Collaboration sub site created successfully" -ForegroundColor Green
    Write-Host "Connecting to " $web.Url -ForegroundColor Green 
    Connect-PnPOnline -Url $web.Url
}
else{
    Write-Host "Collaboration sub site already present, connecting..." -ForegroundColor Green
    Write-Host "Connecting to " $tenantUrl/$collaboratonUrl -ForegroundColor Green
    Connect-PnPOnline -Url "$tenantUrl/$collaboratonUrl"
}
echo $scriptlocation
Invoke-PnPSiteTemplate -Path SiteCatalogue.pnp -ExcludeHandlers "Fields, ContentTypes, Navigation, Pages" -ResourceFolder "$($scriptlocation)\MailTemplates"
# Files are not being uploaded with .pnp file for some reason. For Quick fix added below line
Invoke-PnPSiteTemplate -Path "CollaborationSiteCatalogue-$environment.xml" -Handlers "Files" -ResourceFolder "$($scriptlocation)\MailTemplates"
Write-Host "PnP artefacts applied to Collaboration sub site sucessfully" -ForegroundColor Green

$site = Get-PnPSite


# Change Title => Site name, Remove/Uncheck Item content type in Sites list
#Set-PnPField -List Sites -Identity "Title" -Values
# Remove Item Content type
Remove-PnPContentTypeFromList -List "Sites" -ContentType "Item"
Write-Host "Removed Item Content tytpe from Sites list successfully" -ForegroundColor Green

$field = Get-PnPField -List "Sites" -Identity "Project_x0020_Manager"
$ct = Get-PnPContentType -List "Sites" -Identity "Project Site"

$fieldReferenceLink = New-Object Microsoft.SharePoint.Client.FieldLinkCreationInformation 
$fieldReferenceLink.Field = $field; 
$ct.FieldLinks.Add($fieldReferenceLink)
$ct.Update($false)
$site.Context.ExecuteQuery()
Write-Host "Added Project manager field to Project site list content type successfully" -ForegroundColor Green

$taxfield = Get-PnPField -List "Sites" -Identity "TaxKeyword"
$fieldReferenceLink = New-Object Microsoft.SharePoint.Client.FieldLinkCreationInformation 
$fieldReferenceLink.Field = $taxfield
$ct.FieldLinks.Add($fieldReferenceLink)
$ct.Update($false)
$site.Context.ExecuteQuery()
Write-Host "Added Enterprise keyword field to Project site list content type successfully" -ForegroundColor Green

# Re-order list content types
$ct = Get-PnPContentType -List "Sites" -Identity "Project Site"

<#$viewFields = New-Object System.Collections.Specialized.StringCollection
#Col1 = Internal Name of a field
$viewFields.Add("Title")
$viewFields.Add("ALFA_ProjectDescription")
$viewFields.Add("ALFA_SiteOwners")
$viewFields.Add("ALFA_SiteEditor")
$ct.FieldLinks.Reorder($viewFields)#>
$ct.FieldLinks.Reorder("Title,ALFA_ProjectDescription,ALFA_SiteOwners,ALFA_SiteEditor,Project_x0020_Manager,ALFA_SiteURL,ALFA_SiteStatus,ALFA_SiteStatus,ALFA_Compliant,ALFA_Comment,ALFA_AccessLevel,ALFA_InformationClassification,ALFA_InformationClassification,TaxKeyword,ALFA_Organization")
$ct.Update($false)
$site.Context.Load($ct)
$site.Context.ExecuteQuery()

$ct = Get-PnPContentType -List "Sites" -Identity "Collaboration site"
$ct.FieldLinks.Reorder("Title,ALFA_ProjectDescription,ALFA_SiteOwners,ALFA_SiteEditor,ALFA_SiteURL,ALFA_SiteStatus,ALFA_SiteStatus,ALFA_Compliant,ALFA_Comment,ALFA_AccessLevel,ALFA_InformationClassification,ALFA_InformationClassification,TaxKeyword,ALFA_Organization")
$ct.Update($false)
$site.Context.Load($ct)
$site.Context.ExecuteQuery()
Write-Host "Re ordered list content type field successfully" -ForegroundColor Green

# Apply modern theme to Collaboration landing site
Connect-PnPOnline $tenantAdminUrl
$siteDesignId = Read-Host "Enter Site design id"
Invoke-PnPSiteDesign -Identity $siteDesignId -WebUrl $siteUrl
Write-Host "Applied Alfalaval theme successfully" -ForegroundColor Green

