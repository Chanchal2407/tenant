Param(

   [Parameter(Mandatory=$true)]
   [string]$ShareAdminSiteUrl
)

Connect-PnPOnline -Url $ShareAdminSiteUrl
Apply-PnPProvisioningTemplate -Path "./AdminTemplate/adminportaladmin.xml"
Disconnect-PnPOnline
