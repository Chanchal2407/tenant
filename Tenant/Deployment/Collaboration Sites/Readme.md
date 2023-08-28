##################### Collaboration sites in SharePoint Online #####################################
####################################################################################################

##################### Build and Configuration steps #################################
#Note: 
Refer Collaboration sites Build and Installation document for concreate steps (http://work.alfalaval.org/tools/shareservicesite/Share%20Collaboration%20Sites/Forms/AllItems.aspx). 
below steps is only provides High level glimpses of how to install Alfalaval Collaboration solution.

#STATUS
Development in progress, not yet ready for Test release

#TODO  : Solution level
1. Check SPFX deployment Best practices and set it up accordingly

#TODO : Application level

#PRE-REQUISITES 
#Note: This pre-req. is alredy part of Alfalaval Tenant, so it is not applicable to Alfalaval Production tenant
1. Alfalaval Taxonomy term group must be present in the SharePoint Online tenant.
   Ex: Sample termgroup is part of \Prereq\TermGroup\AlfalavalTaxonomy.xml
   Import it using PnP Powershell command like below.
   Import-PnPTermGroupFromXml -Path "{filepath}"

2. Organization termset must be present in SharePoint Online tenant.
   Ex: Sample termset is part of \Prereq\TermGroup\Organizations.xml
   Import it using PnP Powershell command like below.
   Import-PnPTermSet -Path "{filepath}"

3. SharePoint Online PnP Powershell (Latest version >= March 2018)
   Download it from https://github.com/SharePoint/PnP-PowerShell/releases


# Set OOTB Site Classification in Office 365 tenant
      https://github.com/SharePoint/sp-dev-docs/blob/master/docs/solution-guidance/modern-experience-site-classification.md

# SetUp custom theme
# Note that, this is Tenant wide operation. It will be available on O365 tenant SharePoint Online level
1. Run Set-alfatheme.ps1 to apply Alfalaval theme

# SetUp Site Design for modern themes
Note: Use either SharePoint online powershell console or use PnP Commandlets 
      These site design available for modern team site

1. Connect-SPOService "Admin tenant url"
2. $content = Get-Content -Path "{relativepath}\SiteScript\theme.json" | Out-String
3. Add-SPOSiteScript -Title "Alfalaval theme script" -Content $content
4. Add-SPOSiteDesign -Title "Alfalaval theme design" -SiteScripts {Site script id} -WebTemplate 64

# Deploy assets and SPFx Packages (TODO: Automate it and add steps)
1. Add \CDN\icons\*.png to CDN site collection "Site Assets\Collaboration\logo" (Note : based on where you deploy logo's,LogoUrl in Paremeter of template varies. Double check logos path against Parameter:Logourl path in template )
2. Deploy .sppkg gile to App catalog (IncludeAssets property as true).
3. #TODO : Automate activation of SPFx webpart on Collaboration landing site

# Collaboration Site Catalog site and a subsite

1. Create a classic Team site with STS#0
New-PnPTenantSite -Title "{Title}" -Url "{Relative Url path}" -Description "{Description}" -Owner "{Site colection admin mail id}" -Lcid 1033 -Template STS#0 -TimeZone 4

2. Under SiteCatalogue folder, Run Prepare-SiteCatalogPackage.ps1 and mention environment for which you are running the script (Dev, UAT or Productipon). It created a .PnP file called "SiteCatalgue.pnp"

3. Connect-PnPOnline -Url "Sitecatalogue site url"

4. Run Apply-PnPProvisoningTemplate -Path "{Path to SiteCatalogue.pnp}" -Handlers Fields,ContentType,Navigation,Pages

5. Run New-PnPWeb -Title "Collaboration" -Url "collaboration" -Description "This subsite holds site request form" -Locale 1033 -Template STS#0

6. Connect-PnPOnline -Url "Collaboration subsite"

7. Run Apply-PnPProvisoningTemplate -Path "{Path to SiteCatalogue.pnp}" -ExcludeHandlers Fields,ContentType,Navigation,Pages

# Prepare Collaboration and Project Template and upload

1. Run Convert-PnPFolderToProvisioningTemplate -Out "{First path of folder}\ALFA.Office365.Collaboration\CollaborationSite\CollaborationSite.pnp" -Folder "{First path of folder}\ALFA.Office
365.Collaboration\CollaborationSite"

2. Run Convert-PnPFolderToProvisioningTemplate -Out "{First path of folder}\ALFA.Office365.Collaboration\CollaborationSite\ProjectSite.pnp" -Folder "{First path of folder}\ALFA.Office
365.Collaboration\ProjectSite"

3. This will provide .pnp packages of Collaboration and Project site templates

4. Upload both .pnp packages to Modules library under Collaboration sub site

5. Set Title property of the uploaded item

6. Add entries in Project Templates list selecting the module values (1. Collaboration site, 2. Project site)

7. TODO: Make Template list only field, Rename Title to sitename, Remove Item content type from list, Re order fields
# Register App with Microsoft Graph

# Create Azure web job / Azure function



