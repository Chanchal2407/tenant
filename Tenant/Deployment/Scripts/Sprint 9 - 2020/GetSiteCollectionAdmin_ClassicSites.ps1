cls

#read xml file
[xml]$config = (Get-Content ScriptConfig.xml)

#Variables
$AdminURL = $config.root.shareAdminUrl
$ReportOutput="C:\Rahul\AlfaLaval\Scripts\Sprint 9\6848\SiteCollectionAdmins.csv"
$userName = $config.root.username
$Password = $config.root.password
$cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)
  
Try {
    #Connect to SharePoint Online
    Connect-SPOService -url $AdminURL -Credential $cred
  
    #Get all Site colections
    $Sites = Get-SPOSite -Template STS#0
    $SiteData = @()
     
    #Get Site Collection Administrators of Each site
    Foreach ($Site in $Sites)
    {
        Write-host -f Yellow "Processing Site Collection:"$Site.URL
      
        #Get all Site Collection Administrators
        $SiteAdmins = Get-SPOUser -Site $Site.Url -Limit ALL | Where { $_.IsSiteAdmin -eq $True} | Select DisplayName, LoginName
 
        #Get Site Collection Details
        $SiteAdmins | ForEach-Object {
        $SiteData += New-Object PSObject -Property @{
                'Site Name' = $Site.Title
                'URL' = $Site.Url
                'Site Collection Admins' = $_.DisplayName + " ("+ $_.LoginName +"); "
                }
        }
    }
    $SiteData
    #Export the data to CSV
    $SiteData | Export-Csv $ReportOutput -NoTypeInformation
    Write-Host -f Green "Site Collection Admninistrators Data Exported to CSV!"
}
catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
}