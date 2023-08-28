cls
Add-Type -Path 'C:\Program Files\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline\3.23.2007.1\Microsoft.SharePoint.Client.dll'
Add-Type -Path 'C:\Program Files\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline\3.23.2007.1\Microsoft.SharePoint.Client.Runtime.dll'
#read xml file
[xml]$config = (Get-Content ScriptConfig_Prod.xml)

#Variables
$root = $config.root.RootSite
$inputSites = $config.root.inputSites
$CollabReportOutput = $config.root.CollabReportOutput
$PortalReportOutput=$config.root.PortalReportOutput
$LocalReportOutput=$config.root.PortalReportOutput
$ToolReportOutput=$config.root.PortalReportOutput
$AddOnSitesReportOutput=$config.root.AdditionalReportOutput
$alfalavalTheme = $config.root.AlfalavalTheme
$clientId = $config.root.ClientId
$certificatePath = $config.root.CertificatePath
$certificatePassword = $config.root.CertificatePassword
$tenant = $config.root.Tenant
$UserName = $config.root.Username
$Password = $config.root.Password
$AdminPortalUrl=$config.root.AdminPortalUrl
$LocalSiteLandingURL=$config.root.LocalSiteLanding
$ToolSiteLandingURL=$config.root.ToolSiteLanding
function  Apply-CollaborationSites {
    $BatchSize = 2000
    $ListName = "Sites"
    #Setup Credentials to connect
    $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, (ConvertTo-SecureString $Password -AsPlainText -Force))
    $CollabLandingSiteURL = "https://"+$root + "/Sites/" + $config.root.CollabLandingSiteURL
    Write-host $CollabLandingSiteURL
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($CollabLandingSiteURL)
    $Ctx.Credentials = $Credentials
    Write-host -f Green "Reading all collaboration sites..."
    try {
        $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($CollabLandingSiteURL)
        $Ctx.Credentials = $Credentials
        #Get the List 
        $List = $Ctx.Web.Lists.GetByTitle($ListName) 
        $Ctx.Load($List) 
        $Ctx.ExecuteQuery() 
        #Define Query to get List Items in batch 
        $Query = New-Object Microsoft.SharePoint.Client.CamlQuery 
        $Query.ViewXml = @"
    <View Scope='RecursiveAll'>
        <Query>
            <OrderBy><FieldRef Name='ID' Ascending='TRUE'/></OrderBy>
        </Query>
        <RowLimit Paged="TRUE">$BatchSize</RowLimit>
    </View>
"@
        $SiteData = @()
        #Get List Items in Batch 
        Do { 
            $ListItems = $List.GetItems($Query) 
            $Ctx.Load($ListItems) 
            $Ctx.ExecuteQuery() 
            foreach ($listitem in $listitems) {
   
                $CollabsiteURL = New-Object Microsoft.SharePoint.Client.FieldUrlValue
                $CollabsiteURL = $listitem["ALFA_SiteURL"]
    
                if ($null -ne $CollabsiteURL.URL) {
                    Write-Host $CollabsiteURL.URL
                    try {
                        Connect-PnPOnline $CollabsiteURL.URL -Credentials:ALCredA
                        #Set AL Theme
                        Set-PnPWebTheme -Theme $alfalavalTheme -WebUrl $CollabsiteURL.URL
                        $success = "True"
                    }
                    catch {
                        Write-host "Error processing Site : $($_.Exception.Message)"  -f Red
                        $success = "False"
                    }
                    Disconnect-PnPOnline

                    $objectData = @{
                        SiteURL = $CollabsiteURL.URL;
                        Success = $success;
                                                           
                    }
                    $SiteData += New-Object PSObject -Property $objectData   

                }
            }
            $ListItems.count 
            $Query.ListItemCollectionPosition = $ListItems.ListItemCollectionPosition 
        } 
        While ($null -ne $Query.ListItemCollectionPosition)
        #Export the data to CSV
        $SiteData | Export-Csv $CollabReportOutput -NoTypeInformation -Encoding UTF8
        Write-Host -f Green "Collaboration Sites Report Exported to CSV!"
    }
    catch {
        Write-host "Error Connecting to Collaboration Landing site : $($_.Exception.Message)"  -f Red
    }
}
#Function to process all Tool sites
function Apply-PortalSites {
    #Variables for Processing
    $ListName = "CLC Inclusion List"

    #Setup Credentials to connect
    $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, (ConvertTo-SecureString $Password -AsPlainText -Force))
  
    #Set up the context
    $Context = New-Object Microsoft.SharePoint.Client.ClientContext($AdminPortalUrl) 
    $Context.Credentials = $credentials
   
    #Get the List
    $List = $Context.web.Lists.GetByTitle($ListName)
 
    #sharepoint online get list items powershell
    $ListItems = $List.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery()) 
    $Context.Load($ListItems)
    $Context.ExecuteQuery()       
 
    write-host "Total Number of List Items found:"$ListItems.Count
    $SiteData = @()
    #Loop through each item
    $ListItems | ForEach-Object {
        #Get the Title field value
        $PortalSiteURL = New-Object Microsoft.SharePoint.Client.FieldUrlValue
        $PortalSiteURL = $_["ALFA_ADM_SiteUrl"]
        if ($null -ne $PortalSiteURL.URL) {
            write-host $PortalSiteURL.URL
            try {
                Connect-PnPOnline $PortalSiteURL.URL -Credentials:ALCredA
                #Set AL Theme
                Set-PnPWebTheme -Theme $alfalavalTheme -WebUrl $PortalSiteURL.URL
                $success = "True"
            }
            catch {
                Write-host "Error processing Site : $($_.Exception.Message)"  -f Red
                $success = "False"
            }
            Disconnect-PnPOnline

            $objectData = @{
                SiteURL = $PortalSiteURL.URL;
                Success = $success;
                                       
            }
            $SiteData += New-Object PSObject -Property $objectData   
        }
    }
     #Export the data to CSV
     $SiteData | Export-Csv $PortalReportOutput -NoTypeInformation -Encoding UTF8
     Write-Host -f Green "Portal Sites Report Exported to CSV!"  
}
#Function to process all Local Sites
function Apply-LocalSites {
    #Variables for Processing
    $ListName = "All Local sites"

    #Setup Credentials to connect
    $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, (ConvertTo-SecureString $Password -AsPlainText -Force))
  
    #Set up the context
    $Context = New-Object Microsoft.SharePoint.Client.ClientContext($LocalSiteLandingURL) 
    $Context.Credentials = $credentials
   
    #Get the List
    $List = $Context.web.Lists.GetByTitle($ListName)
 
    #sharepoint online get list items powershell
    $ListItems = $List.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery()) 
    $Context.Load($ListItems)
    $Context.ExecuteQuery()       
 
    write-host "Total Number of Local Sites:"$ListItems.Count
    $SiteData = @()
    #Loop through each item
    $ListItems | ForEach-Object {
        #Get the Title field value
        $LocalSiteURL = New-Object Microsoft.SharePoint.Client.FieldUrlValue
        $LocalSiteURL = $_["SiteURL"]
        if ($null -ne $LocalSiteURL.URL) {
            write-host $LocalSiteURL.URL
            try {
                Connect-PnPOnline $LocalSiteURL.URL -Credentials:ALCredA
                Write-Host "Connected to Local Site"
                #Set AL Theme
                Set-PnPWebTheme -Theme $alfalavalTheme -WebUrl $LocalSiteURL.URL
                $success = "True"
            }
            catch {
                Write-host "Error processing Local Site : $($_.Exception.Message)"  -f Red
                $success = "False"
            }
            Disconnect-PnPOnline

            $objectData = @{
                SiteURL = $LocalSiteURL.URL;
                Success = $success;
                                       
            }
            $SiteData += New-Object PSObject -Property $objectData   
        }
    }
     #Export the data to CSV
     $SiteData | Export-Csv $LocalReportOutput -NoTypeInformation -Encoding UTF8
     Write-Host -f Green "Local Sites Report Exported to CSV!"  
}
#Function to process Portal Sites from CLC List
function Apply-ToolSites {
    #Variables for Processing
    $ListName = "All Tool sites"

    #Setup Credentials to connect
    $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, (ConvertTo-SecureString $Password -AsPlainText -Force))
  
    #Set up the context
    $Context = New-Object Microsoft.SharePoint.Client.ClientContext($ToolSiteLandingURL) 
    $Context.Credentials = $credentials
   
    #Get the List
    $List = $Context.web.Lists.GetByTitle($ListName)
 
    #sharepoint online get list items powershell
    $ListItems = $List.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery()) 
    $Context.Load($ListItems)
    $Context.ExecuteQuery()       
 
    write-host "Total Number of Tools Sites found:"$ListItems.Count
    $SiteData = @()
    #Loop through each item
    $ListItems | ForEach-Object {
        #Get the Title field value
        $ToolSiteURL = New-Object Microsoft.SharePoint.Client.FieldUrlValue
        $ToolSiteURL = $_["SiteURL"]
        if ($null -ne $ToolSiteURL.URL) {
            write-host $ToolSiteURL.URL
            try {
                Connect-PnPOnline $ToolSiteURL.URL -Credentials:ALCredA
                Write-Host "Connected to Tool site"
                #Set AL Theme
               Set-PnPWebTheme -Theme $alfalavalTheme -WebUrl $ToolSiteURL.URL
               Write-Host "Applied the theme"
                $success = "True"
            }
            catch {
                Write-host "Error processing Site : $($_.Exception.Message)"  -f Red
                $success = "False"
            }
            Disconnect-PnPOnline
            Write-Host "Disconnected PnP Online"

            $objectData = @{
                SiteURL = $ToolSiteURL.URL;
                Success = $success;
                                       
            }
            $SiteData += New-Object PSObject -Property $objectData   
        }
    }
     #Export the data to CSV
     $SiteData | Export-Csv $ToolReportOutput -NoTypeInformation -Encoding UTF8
     Write-Host -f Green "Tool Sites Report Exported to CSV!"  
}
function Apply-AdditionalSites {
    # Import sites
    $siteURLs = Import-Csv $inputSites -Header URL 

    $SiteData = @()

    Foreach ($Site in $siteURLs.URL) {    
        Write-host -f Yellow "Processing Site Collection:"$Site    
   
        try {
          Connect-PnPOnline -Url $Site -ClientId $clientId -CertificatePath $certificatePath -CertificatePassword (ConvertTo-SecureString -String $certificatePassword -AsPlainText -Force) -Tenant $tenant
            $success = "True"
            $exists = "False"
           # Write-Host "Connected to Site.."
            #Write-Host $temp.Title
            #Set AL Theme
            Set-PnPWebTheme -Theme $alfalavalTheme -WebUrl $Site    
        }
        catch {
            Write-host "Error processing Site : $($_.Exception.Message)"  -f Red
            $success = "False"
            $exists = $_.Exception.Message        
        }

        Disconnect-PnPOnline

        $objectData = @{
            SiteURL = $Site;
            Success = $success;
            Exists  = $exists;                                       
        }
	    
        $SiteData += New-Object PSObject -Property $objectData   
    
    }
    #Export the data to CSV
    $SiteData | Export-Csv $AddOnSitesReportOutput -NoTypeInformation -Encoding UTF8
    Write-Host -f Green "Report Exported to CSV!"

}
#Function call to Apply theme to All collaboration sites
#Apply-CollaborationSites
#Function call to Apply theme to All Portal Sites
#Apply-PortalSites
#Function call to Apply theme to Additional sites
#Apply-AdditionalSites
#Apply-LocalSites
Apply-ToolSites

