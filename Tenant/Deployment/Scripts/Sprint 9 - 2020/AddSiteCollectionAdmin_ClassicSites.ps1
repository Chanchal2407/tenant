cls

#read xml file
[xml]$config = (Get-Content ScriptConfig.xml)

#Variables
$AdminURL = $config.root.shareAdminUrl
$ADGroupID = $config.root.ADGroupID 
$userName = $config.root.username
$Password = $config.root.password
$cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)
 
$LoginName = "c:0t`.c`|tenant`|$ADGroupID"
$SiteURL = ""
 
Try {
    #Connect to SharePoint Online
    Connect-SPOService -url $AdminURL -Credential $cred
  
    $allClassicSites = Get-SPOSite -Template STS#0
    
    ForEach ($siteURLObject in $allClassicSites.url) {
        
        $SiteURL = $siteURLObject
    
        $Site = Get-SPOSite $SiteURL
    
        Write-host -f Yellow "Adding AD Group ShareOnline_Support_Admin as Site Collection Administrator..."
        Set-SPOUser -site $Site -LoginName $LoginName -IsSiteCollectionAdmin $True
        Write-host -f Green "Done!"
    }
}
Catch {
    write-host -f Red "Error:" $_.Exception.Message
}
