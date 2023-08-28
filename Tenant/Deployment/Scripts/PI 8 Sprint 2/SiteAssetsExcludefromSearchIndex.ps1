#This script is used to Exclude "Site Assets" from search by changing the Crawl settings in Library settings.
#Author: Karteek Saripalli
#Reviewer: Gurudatt Bhat
#Created Date:22/02/2021
#####################################################################
param (
	[Parameter(Mandatory=$true)][string]$AdminPortal,
	[Parameter(Mandatory=$true)][string]$ShareRootURL
 )
#Getting credentials
$cred = Get-Credential
#Connecting to Admin Portal Site
Write-Host "Script Execution Started" -ForegroundColor DarkGreen
Write-Host "Connecting to AdminPortal Site..." -ForegroundColor DarkGreen
Connect-PnPOnline -Url $AdminPortal -Credentials $cred
#Connection to CLC List
Write-Host "Connecting to CLC List..." -ForegroundColor DarkGreen
$clcList=Get-PnPList -Identity "CLC Inclusion List"
Write-Host "Getting CLC Items..." -ForegroundColor DarkGreen
$clcListItems= Get-PnPListItem -List $clcList
Disconnect-PnPOnline
#function to connect to the site and add "Everyone excpet external users to "Visitors" group.
function UpdateSearchIndexing($site){
    Write-Host "Connecting to the Site:$site" -ForegroundColor DarkGreen
    Connect-PnPOnline -Url $site -Credentials $cred
    $ctx=Get-PnPContext
    $siteAssets=Get-PnPList -Identity "Site Assets"
    if($null -ne $siteAssets){
           if($false -eq $siteAssets.NoCrawl){
           $siteAssets.NoCrawl=$true
           $siteAssets.update()
           $ctx.ExecuteQuery()
           }
            
        }
        #Disconnect PnP-Online
   $subSites= Get-PnPSubWebs -Recurse
   Disconnect-PnPOnline
   if($null -ne $subSites){
    foreach ($subSite in $subSites) {
    UpdateSearchIndexingofSubSite($subSite.URL)
    }
        
   }
   
   }
function UpdateSearchIndexingofSubSite($site){
    Write-Host "Connecting to the Sub Site:$site" -ForegroundColor DarkGreen
    Connect-PnPOnline -Url $site -Credentials $cred
    $ctx=Get-PnPContext
    $siteAssets=Get-PnPList -Identity "Site Assets"
    if($null -ne $siteAssets){
           if($false -eq $siteAssets.NoCrawl){
           $siteAssets.NoCrawl=$true
           $siteAssets.update()
           $ctx.ExecuteQuery()
           }
            
        }else{
         Write-Host "Site Assets doesnt exists" -ForegroundColor DarkGreen
        }
   #Disconnect PnP-Online
   Disconnect-PnPOnline
   }
#Connecting to Share
UpdateSearchIndexing($ShareRootURL);
#Iterating throught the CLC list items
Write-Host $clcListItems.Count " sites found in CLC" -ForegroundColor DarkGreen
Write-Host "Iterating through CLC Sites..." -ForegroundColor DarkGreen

#foreach ($listItem in $clcListItems) {

#   if($listItem["ALFA_ADM_SiteUrl"].URL.Contains("*")){
   
 #  }
  # else{
	#UpdateSearchIndexing($listItem["ALFA_ADM_SiteUrl"].URL)
    #}
   
#}
 Write-Host "Process Completed" -ForegroundColor DarkGreen

