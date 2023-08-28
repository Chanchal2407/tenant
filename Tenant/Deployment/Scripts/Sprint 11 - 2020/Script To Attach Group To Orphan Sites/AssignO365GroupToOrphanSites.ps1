cls

#read xml file
[xml]$config = (Get-Content ScriptConfig_Prod.xml)

#Variables
$alfaTenantUrl = $config.root.shareTenantUrl
$tenantAdminUrl = $config.root.shareAdminUrl
$username = $config.root.username
$password = $config.root.password
$inputOrphanSite = $config.root.InputOrphanSite
$ReportOutput = $config.root.ReportOutput

$managedPath = "sites"

$encpassword = convertto-securestring -String $password -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $encpassword

Connect-SPOService -Url $tenantAdminUrl -Credential $cred 

$siteURLs = Import-Csv $inputOrphanSite -Header URL 

$SiteData = @()

Foreach ($Site in $siteURLs.URL)
{
    
    Write-host -f Yellow "Processing Site Collection:"$Site
    
    $thisSite = Get-SPOSite -Identity $Site           
    
    $oldGrpID = $thisSite.GroupId
    $siteTitle = $thisSite.Title
    $existingUrl = $thisSite.Url
    
    $nameAlias =  $existingUrl.Substring($existingUrl.LastIndexOf("/") + 1)
    $contentType =  $nameAlias.Substring(0, $nameAlias.IndexOf("-"))
       
    $cleanName = $siteTitle -replace '[^a-z0-9]'
    
    $grpEmailAlias = $contentType + "-" + $cleanName 
    
    
    # MailNickName character limit is 64. so to be on safer side, truncate it at 59
    if($grpEmailAlias.length -ge 59) {
         $grpEmailAlias = $grpEmailAlias.Substring(0,58)
    }
    if([String]::IsNullOrWhiteSpace($grpEmailAlias)){
        $grpEmailAlias = "team"
    }

    $counter = 1
    $url = "$alfaTenantUrl/$managedPath/$grpEmailAlias"
    $doCheck = $true	
    $newgrpEmailAlias = $grpEmailAlias
    $newurl = $url
     
    while ($doCheck) {
        $appendedurl = $newurl + $counter
        $appendedgrpEmailAlias = $newgrpEmailAlias + $counter
                
        #$objSite = Get-SPOSite | Where-Object Url -eq $appendedurl
        
        try{         
            Get-SPOSite -Identity $appendedurl
            $counter++
            write-host "Group Alias : " $appendedgrpEmailAlias
            write-host "Site Url found : " $appendedurl          
        }
        Catch { 
            write-host “error in finding the site”
            $doCheck = $false
            write-host "New Group Alias : " $appendedgrpEmailAlias
            write-host "Site Url NOT Found: " $appendedurl 
        }

        #if($objSite) {
        #    #$newgrpEmailAlias = $grpEmailAlias + $counter
        #    #$newurl = $url + $counter
        #    $counter++
        #    write-host "Group Alias : " $appendedgrpEmailAlias
        #    write-host "Site Url found : " $appendedurl 
        #} else {
        #    $doCheck = $false
        #    write-host "New Group Alias : " $appendedgrpEmailAlias
        #    write-host "Site Url NOT Found: " $appendedurl 
        #}
    }
    Write-Host ""
       
    #Apply new group to orphan site
    #Set-SPOSiteOffice365Group -Site $Site -DisplayName $siteTitle -Alias $appendedgrpEmailAlias
    
    $newGrpID = $thisSite.GroupId

    Write-Host "Site                  : " $Site
    Write-Host "Old Group ID          : " $oldGrpID
    Write-Host "Site Title/DisplayName: " $siteTitle
    Write-Host "New Url               : " $appendedurl
    Write-Host "New Group Email Alias : " $appendedgrpEmailAlias
    Write-Host "New Group ID          : " $newGrpID

    $objectData = @{
            SiteURL = $Site;
            OldGroupID = $oldGrpID;
            SiteTitle_DisplayName = $siteTitle;
            NewTestUrl = $appendedurl;
            NewGroupEmailAlias = $appendedgrpEmailAlias;
            NewGroupID = $newGrpID;         
	}
	    
    $SiteData += New-Object PSObject -Property $objectData   
    
}
$SiteData
#Export the data to CSV
$SiteData | Export-Csv $ReportOutput -NoTypeInformation -Encoding UTF8
Write-Host -f Green "Site Usage Data Exported to CSV!"

Disconnect-SPOService