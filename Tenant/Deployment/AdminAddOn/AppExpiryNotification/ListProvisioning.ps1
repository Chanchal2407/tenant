#Powershell script to Create a List "Apps for Authentication" in AdminPortal Site
Connect-PnPOnline -Url "https://alfalavalonline.sharepoint.com/sites/AdminPortalQA" -Credentials:ALCredA
Apply-PnPProvisioningTemplate -Path "C:\Users\INPUKSI\source\repos\Share Realization Project\Deployment\AdminAddOn\AppExpiryNotification\AdminPortalNewListUpdated.xml"
Disconnect-PnPOnline