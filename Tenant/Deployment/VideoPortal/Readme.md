# Deployment Guide for Video Portal Site Design & Runbook  

- Clone the "ITSOLNCF.ShareRealization" repository code in the local machine.

**Repository url**: https://dev.azure.com/alfalaval/Alfa%20Laval%20Portfolio/_git/ITSOLNCF.ShareRealization

- Navigate to the Deployment folder and the VideoPortal folder.
- Set the Authentication value in "VideoPortalSitesConfig.json" file as shown as an example
 
        	"username": "user@tenant.onmicrosoft.com",
        	"password": "pass",
        	"tenantUrl": "https://tenant.sharepoint.com",
        	"sharePointAdminUrl": "https://tenant-admin.sharepoint.com",
        	"environment": "PROD"
- Then navigate to "VideoPortalSiteDesign" folder and respective environment folder (ex: DEV)
- Change the "hubSiteId" respective to the video portal hub site in "VideoPortal-script-joinToHub.json" file.
- Open the "VideoPortal-script-pageFooterExtension.json" file and change the following settings
        	"verb": "associateExtension",
        	"title": "SharePageFooter-dev",
        	"location": "ClientSideExtension.ApplicationCustomizer",
        	"clientSideComponentId": "a29efd4f-3f67-4677-bf4e-2a8e1779b668"
- Run "AddVideoPortalSiteDesign.ps1" file. It creates "AlfaLaval design -  Video Portal site"  Site Design in Alfa Laval tenant.
- Navigate to the portal landing site "https://alfalavalonline.sharepoint.com/sites/portalsitelanding" and upload "OrganizationVideoChannel.pnp" template in the Site Assets library. 
- Then Submit a portal site request for the "Organization Video Channel" type.
- After site request is approved a video portal site will be created with the defined template.