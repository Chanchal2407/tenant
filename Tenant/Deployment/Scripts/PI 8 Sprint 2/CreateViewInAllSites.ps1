#This script is used to  add view to show all Pages Modified by SharePointApp in All Portal/Local/Tools Site Visitors Group
#Author :Karteek Saripalli
#Reviewer: 
#Created Date:08/03/2021
##############################################################################################################
param (
	[Parameter(Mandatory=$true)][string]$AdminPortal
 )
#Forming Admin URL
$temp=$AdminPortal -split ".sharepoint"
$AdminURL=$temp[0]+"-admin.sharepoint.com"
Write-Host "SharePoint Admin URL:" $AdminURL -ForegroundColor DarkGreen
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
#Custom Function to Check if View exists
<#Function Check-ViewExists()
{
    Try { 
        $view=Get-PnPView -List "Site Pages" -Identity "UnpublshedbySharePointApp"
        Return $True
        }
        catch{
            Return $false
        }
    
}#>
#function to connect to the site and add "Everyone excpet external users to "Visitors" group.
function AddViewtoSite($site){
    Write-Host "Connecting to the Site:$site" -ForegroundColor DarkGreen
    Connect-PnPOnline -Url $site -Credentials $cred
    $visitorGroup=Get-PnPGroup -AssociatedVisitorGroup
    Add-PnPView -Fields "LinkFilename","Modified","Editor","_UIVersionString","Created" -List "Site Pages" -Title "UnpublishedbySharePointApp" -Query "<Where><Eq><FieldRef Name = 'Editor' /><Value Type = 'Text'>SharePoint App</Value></Eq></Where>" | out-Null
   Write-Host "Getting Subsites of the Site:$site" -ForegroundColor DarkGreen
   $allSubSites=Get-PnPSubWebs -Recurse
   #Disconnect PnP-Online
   Disconnect-PnPOnline
   if($null -ne $allSubSites){
   Write-Host $allSubSites.Count " subsites found in the site $site" -ForegroundColor DarkGreen
    foreach ($subSite in $allSubSites) {
    AddViewtoSubSite($subSite.URL)
    }
        
   }else{
    Write-Host "No Subsites present in the Site:$site" -ForegroundColor DarkGreen
   }
   }
#function to connect to the subsite and create view.
function AddViewtoSubSite($site){
    Write-Host "Connecting to the SubSite:$site" -ForegroundColor DarkGreen
    Connect-PnPOnline -Url $site -Credentials $cred
    Add-PnPView -Fields "LinkFilename","Modified","Editor","_UIVersionString","Created" -List "Site Pages" -Title "UnpublishedbySharePointApp" -Query "<Where><Eq><FieldRef Name = 'Editor' /><Value Type = 'Text'>SharePoint App</Value></Eq></Where>" | out-Null
    #Add-PnPView -Fields "LinkFilename","Modified","Editor","_UIVersionString","Created" -List "Site Pages" -Title "UnpublshedbySharePointApp" -Query "<Where><Eq><FieldRef Name = 'Editor' /><Value Type = 'Text'>SharePoint App</Value></Eq></Where>" | out-Null
   #Disconnect PnP-Online
   Disconnect-PnPOnline
   }
#Iterating throught the CLC list items
Write-Host $clcListItems.Count " sites found in CLC" -ForegroundColor DarkGreen
Write-Host "Iterating through CLC Sites..." -ForegroundColor DarkGreen

foreach ($listItem in $clcListItems) {

   if($listItem["ALFA_ADM_SiteUrl"].URL.Contains("*")){
    if($listItem["ALFA_ADM_SiteUrl"].Description.Contains("Local")){
        Write-Host "Getting all local sites..." -ForegroundColor DarkGreen
        Connect-PnPOnline -Url $AdminURL -Credentials $cred
        $localSites = Get-PnPTenantSite -Filter "Url -like 'sites/LocalSite'"
        foreach ($localSite in $localSites) {
         AddViewtoSite($localSite.URL)
        }

        
    }
    if($listItem["ALFA_ADM_SiteUrl"].Description.Contains("Tool")){
        Write-Host "Getting all tool sites..." -ForegroundColor DarkGreen
        Connect-PnPOnline -Url $AdminURL -Credentials $cred
        $toolSites =  Get-PnPTenantSite  -Filter "Url -like 'sites/ToolSite'"
        foreach ($toolSite in $toolSites) {
        AddViewtoSite($toolSite.URL)
        }

        
    }
   
   }
   else{
   AddViewtoSite($listItem["ALFA_ADM_SiteUrl"].URL)
    }
}

Write-Host "Process Completed" -ForegroundColor DarkGreen
