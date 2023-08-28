cls

#read xml file
[xml]$config = (Get-Content ScriptConfig_Dev.xml)

#Variables
$inputSites = $config.root.inputSites
$ReportOutput = $config.root.ReportOutput
$topNavTemplate = $config.root.TopNavTemplate
$alfalavalTheme = $config.root.AlfalavalTheme
$clientId = $config.root.ClientId
$certificatePath = $config.root.CertificatePath
$certificatePassword = $config.root.CertificatePassword
$tenant = $config.root.Tenant

# Import sites
$siteURLs = Import-Csv $inputSites -Header URL 

$SiteData = @()

Foreach ($Site in $siteURLs.URL)
{    
    Write-host -f Yellow "Processing Site Collection:"$Site    
   
    Connect-PnPOnline -Url $Site -ClientId $clientId -CertificatePath $certificatePath -CertificatePassword (ConvertTo-SecureString -String $certificatePassword -AsPlainText -Force) -Tenant $tenant
    $success = "True"

    try{
        #Set AL Theme
        Set-PnPWebTheme -Theme "Alfalaval theme" -WebUrl $Site 
        
        #Set share TopNav
        Apply-PnPProvisioningTemplate -Path $topNavTemplate 
    }
    catch{
        Write-host "Error processing Site : $($_.Exception.Message)"  -f Red
        $success = "False"        
    }

    Disconnect-PnPOnline

    $objectData = @{
            SiteURL = $Site;
            Success = $success;                                       
	}
	    
    $SiteData += New-Object PSObject -Property $objectData   
    
}
$SiteData
#Export the data to CSV
$SiteData | Export-Csv $ReportOutput -NoTypeInformation -Encoding UTF8
Write-Host -f Green "Report Exported to CSV!"



