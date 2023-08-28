#This script is used to "Everyone except external users" to All Portal/Local/Tools Site Visitors Group
#Author :Karteek Saripalli
#Reviewer: Gurudatt Bhat
#Created Date:18/02/2021
##############################################################################################################
param (
	[Parameter(Mandatory=$true)][string]$AdminPortal
 )
#Forming Admin URL
$temp=$AdminPortal -split ".sharepoint"
$AdminURL=$temp[0]+"-admin.sharepoint.com"
#Getting credentials
$cred = Get-Credential
#Connecting to Admin Portal Site
Write-Host "Script Execution Started" -ForegroundColor DarkGreen
Write-Host "Connecting to AdminPortal Site..." -ForegroundColor DarkGreen
Connect-PnPOnline -Url $AdminPortal -Credentials $cred
#Connection to CLC List
Write-Host "Conncting to CLC List..." -ForegroundColor DarkGreen
$clcList=Get-PnPList -Identity "CLC Inclusion List"
Write-Host "Getting CLC Items..." -ForegroundColor DarkGreen
$clcListItems= Get-PnPListItem -List $clcList
Disconnect-PnPOnline
#function to connect to the site and add "Everyone excpet external users to "Visitors" group.
function AddGrouptoSite($site){
    Write-Host "Connecting to the Site:$site" -ForegroundColor DarkGreen
    Connect-PnPOnline -Url $site -Credentials $cred
    $visitorGroup=Get-PnPGroup -AssociatedVisitorGroup
    $groupMembers=Get-PnPGroupMembers -Identity $visitorGroup
    $check=$false
    foreach ($groupMember in $groupMembers) {
        if($groupMember.LoginName.Contains("spo-grid-all-users")){
            $check=$true
        }
    }
        if($check){
            Add-PnPUserToGroup -LoginName "c:0-.f|rolemanager|spo-grid-all-users/ed5d5f47-52dd-48af-90ca-f7bd83624eb9" -Identity $visitorGroup
            
        }
   
   Write-Host "Getting Subsites of the Site:$site" -ForegroundColor DarkGreen
   $allSubSites=Get-PnPSubWebs -Recurse
   #Disconnect PnP-Online
   Disconnect-PnPOnline
   if($null -ne $allSubSites){
   Write-Host $allSubSites.Count " subsites found in the site $site" -ForegroundColor DarkGreen
    foreach ($subSite in $allSubSites) {
    AddGrouptoSubSite($subSite.URL)
    }
        
   }else{
    Write-Host "No Subsites present in the Site:$site" -ForegroundColor DarkGreen
   }
   }
#function to connect to the subsite and add "Everyone excpet external users to "Visitors" group.
function AddGrouptoSubSite($site){
    Write-Host "Connecting to the SubSite:$site" -ForegroundColor DarkGreen
    Connect-PnPOnline -Url $site -Credentials $cred
    $visitorGroup=Get-PnPGroup -AssociatedVisitorGroup
    $groupMembers=Get-PnPGroupMembers -Identity $visitorGroup
    $check=$false
    foreach ($groupMember in $groupMembers) {
        if($groupMember.LoginName.Contains("spo-grid-all-users")){
            $check=$true
        }
    }
        if($check){
            Add-PnPUserToGroup -LoginName "c:0-.f|rolemanager|spo-grid-all-users/ed5d5f47-52dd-48af-90ca-f7bd83624eb9" -Identity $visitorGroup
            
        }
   #Disconnect PnP-Online
   Disconnect-PnPOnline
   }
#Iterating throught the CLC list items
Write-Host $clcListItems.Count " sites found in CLC" -ForegroundColor DarkGreen
Write-Host "Iterating through CLC Sites..." -ForegroundColor DarkGreen
Write-Host "SharePoint Admin URL:" $AdminURL -ForegroundColor DarkGreen
foreach ($listItem in $clcListItems) {

   if($listItem["ALFA_ADM_SiteUrl"].URL.Contains("*")){
    if($listItem["ALFA_ADM_SiteUrl"].Description.Contains("Local")){
        Write-Host "Getting all local sites..." -ForegroundColor DarkGreen
        Connect-PnPOnline $AdminURL -Credentials $cred
        $localSites = Get-PnPTenantSite -Filter "Url -like 'sites/LocalSite'"
        foreach ($localSite in $localSites) {
         AddGrouptoSite($localSite.URL)
        }

        
    }
    if($listItem["ALFA_ADM_SiteUrl"].Description.Contains("Tool")){
        Write-Host "Getting all tool sites..." -ForegroundColor DarkGreen
        Connect-PnPOnline $AdminURL -Credentials $cred
        $toolSites =  Get-PnPTenantSite  -Filter "Url -like 'sites/ToolSite'"
        foreach ($toolSite in $toolSites) {
        AddGrouptoSite($toolSite.URL)
        }

        
    }
   
   }
   else{
   AddGrouptoSite($listItem["ALFA_ADM_SiteUrl"].URL)
    }
}

Write-Host "Process Completed" -ForegroundColor DarkGreen
