##################### Local Site Landing site (Hub site) SharePoint Online #####################################
####################################################################################################

##################### Build and Configuration steps #################################
#Note: 
Below steps provides details of how to install Alfalaval Local site landing site.
By request the script will autmatically import Business Function taxonomy term set under Share term group.
The script will create Local Site Landing site as a hub site by using Comunication site as a template. It will add in the SiteConfing.json specified users and groups to the admin group,
 thus allowing to connect local sites with the hub site.
	The script ensures if Local Site landing site already exists, and by request it will be posible to remove existing site and create new one instead. 
	Note, that all the data in existing site will be lost when removing it.

#STATUS
Development in progress, not yet ready for Test release

#TODO  : Solution level
1. Check SPFX deployment Best practices and set it up accordingly

#TODO : Application level

#In \Deployment\Local Sites\SiteConfig.json :
	1. "OrganizationSettings" section must contain correct information about tenant on which Local Site Landing site will be installed.
	2. "SiteCollections" must containg information about Local Site Landing site itself - Title, Site URL, Site template and hub site admins (if more than one, then should be separated by ",")

#PRE-REQUISITES 
#Note: This pre-req. is alredy part of Alfalaval Tenant, so it is not applicable to Alfalaval Production tenant
	1. Share term group must be present in the SharePoint Online tenant.
		Ex: Sample termgroup is part of \Deployment\Local Sites\ShareIntranetLocalsiteTaxonomies.xml
		Import of Business Function taxonomy is included in RunDeployment.ps1 script and importing of it always will be requested during start of deployment and can be applied by entering "y"


	2. SharePoint Online PnP Powershell (Latest version >= May 2018)
		Download it from https://github.com/SharePoint/PnP-PowerShell/releases




