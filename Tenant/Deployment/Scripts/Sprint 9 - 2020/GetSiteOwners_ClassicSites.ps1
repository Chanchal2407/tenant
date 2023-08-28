cls

#read xml file
[xml]$config = (Get-Content ScriptConfig.xml)

#Variables
$AdminURL = $config.root.shareAdminUrl
$ReportOutput=$config.root.ReportOutput
$userName = $config.root.username
$Password = $config.root.password
$cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)
  
Try {
    #Connect to SharePoint Online
    Connect-PnPOnline -Url $AdminURL -Credential $cred
  
    #Get all Site colections
    $Sites = Get-PnPTenantSite -Template STS#0    
    Disconnect-PnPOnline

    $SiteData = @()

    #Get Site Collection Administrators of Each site
    Foreach ($Site in $Sites.url)
    {
        Write-host -f Yellow "Processing Site Collection:"$Site
        
        Connect-PnPOnline -Url $Site -Credential $cred
        Get-PnPGroup -AssociatedOwnerGroup
        $SCRIPT6_siteOwner = (Get-PnPGroup -AssociatedOwnerGroup | Get-PnPGroupMembers | Select-Object -ExpandProperty Email) -join ","        
        Write-Host "SiteOwner: " $SCRIPT6_siteOwner
                
        $objectData = @{		            
            SiteOwners = $SCRIPT6_siteOwner;
            SiteURL = $Site            
	    }
	    
        $SiteData += New-Object PSObject -Property $objectData
        
    }
    $SiteData
    #Export the data to CSV
    $SiteData | Export-Csv $ReportOutput -NoTypeInformation
    Write-Host -f Green "Site Owners Data Exported to CSV!"
}
catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
}