cls

#read xml file
[xml]$config = (Get-Content ScriptConfig.xml)

#Variables
$AdminURL = $config.root.shareAdminUrl
$ReportOutput=$config.root.ReportOutput
$userName = $config.root.username
$Password = $config.root.password
$cred = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $userName, $(convertto-securestring $Password -asplaintext -force)
$appId = $config.root.AppId
$appSecret = $config.root.AppSecret
$aadDomain = $config.root.AADDomain

Try {
    #Connect to SharePoint Online
    Connect-PnPOnline -Url $AdminURL -Credential $cred
  
    #Get all Site colections
    $Sites = Get-PnPTenantSite -Template STS#0    
    Disconnect-PnPOnline

    $SiteData = @()

    #Get app details and connect
    Connect-PnPOnline -AppId $appId -AppSecret $appSecret -AADDomain $aadDomain
    $token = Get-PnPAccessToken
    $headers = @{"Content-Type" = "application/json" ; "Authorization" = "Bearer " + $token}
    
    #Get sharepoint site activity from Graph Api
    $SharepointUsageReportsURI = "https://graph.microsoft.com/v1.0/reports/getSharePointSiteUsageDetail(period='D7')"

    $Results = (Invoke-RestMethod -Method Get -Uri $SharepointUsageReportsURI -Headers $headers) -replace "ï»¿", "" | ConvertFrom-Csv
    Disconnect-PnPOnline

    #Get Site Collection Administrators of Each site
    Foreach ($Site in $Sites.url)
    {
        Write-host -f Yellow "Processing Site Collection:"$Site
        
        Connect-PnPOnline -Url $Site -Credential $cred
        Get-PnPGroup -AssociatedOwnerGroup
        $siteOwner = (Get-PnPGroup -AssociatedOwnerGroup | Get-PnPGroupMembers | Select-Object -ExpandProperty Email) -join ","  
        
        Get-PnPGroup -AssociatedMemberGroup
        $siteMember = (Get-PnPGroup -AssociatedMemberGroup | Get-PnPGroupMembers | Select-Object -ExpandProperty Email) -join ","
        
        $siteCollAdmin = (Get-PnPSiteCollectionAdmin | select -ExpandProperty Email) -join ","      
        Disconnect-PnPOnline
        
        $Res = $Results | Where { $_."Site URL" -eq $Site }
        
        $lastActivityDate = $Res."Last Activity Date"
        $storageUsed = $Res."Storage Used (Byte)"                        
        
        Write-Host "Site Owner: " $siteOwner
        Write-Host "Site Member: " $siteMember
        Write-Host "Site Collection Admin: " $siteCollAdmin
        Write-Host "Last Activity Date: " $lastActivityDate      
        Write-Host "Storage Used GB: " ($storageUsed/1GB).ToString(".00")
        Write-Host "Storage Used MB: " ($storageUsed/1MB).ToString(".00")
        Write-Host "Site URL: " $Site
        Write-Host "Graph API Output: " $Res
        
        $objectData = @{
            SiteURL = $Site;
            LastActivityDate = $lastActivityDate;
            StorageUsed_GB = ($storageUsed/1GB).ToString(".00");
            StorageUsed_MB = ($storageUsed/1MB).ToString(".00");
            SiteCollectionAdmin = $siteCollAdmin;
            SiteMembers = $siteMember;		            
            SiteOwners = $siteOwner            		                        
	    }
	    
        $SiteData += New-Object PSObject -Property $objectData
        
    }
    $SiteData
    #Export the data to CSV
    $SiteData | Export-Csv $ReportOutput -NoTypeInformation -Encoding UTF8
    Write-Host -f Green "Site Usage Data Exported to CSV!"
}
catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
}