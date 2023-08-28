# Pre-Req : Import PnP Powershell in Windows powershell before running the script
# TBD / TODO:  UsageGuidelinesUrl must be updated to valid alfalaval page
# For exisitng environmant, please run below command to add/remove new classifications
# Add-PnPSiteClassification -Classifications "Public","Business","Strictly Confidential","Confidential"
# Remove-PnPSiteClassification -Classifications "Private"
# Remove-PnPSiteClassification -Classifications "Internal"
#
#
# Change History
# 19/09/2022 - Ravi Rachchh - Classifications changed as per AL production

$siteUrl = Read-Host "Enter tenant url (Ex: https://xxx.sharepoint.com)"

Connect-PnPOnline -Url $siteUrl -Scopes "Directory.ReadWrite.All"
Enable-PnPSiteClassification -Classifications "Public","Business","Confidential","Strictly Confidential" -UsageGuidelinesUrl "http://aka.ms/sppnp" -DefaultClassification "Business"
Disconnect-PnPOnline