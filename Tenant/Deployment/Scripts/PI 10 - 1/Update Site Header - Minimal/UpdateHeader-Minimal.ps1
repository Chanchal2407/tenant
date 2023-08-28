cls
#region begin input
############### Input - Start ###############

#read xml file
[xml]$config = (Get-Content ScriptConfig_Prod.xml)

#SharePoint Online.
$SPOServiceRootUrl = $config.root.SPOServiceRootUrl
$SPOServiceUsername = $config.root.SPOServiceUsername
$SPOServicePassword = $config.root.SPOServicePassword
$CollaborationSitesUrl = $config.root.CollaborationSitesUrl
$IsCSV = $config.root.IsCSV

#Files.
$Files = $config.root.ReportOutput
$InputFiles =  $config.root.inputSites

############### Input - End ###############
#endregion

#region begin functions
############### Functions - Start ###############

#Creates a PS credential object.
Function Create-PSCredential
{
    [cmdletbinding()]	
		
    Param
    (
        [Parameter(Mandatory=$true, HelpMessage="Please provide a valid username, example 'Domain\Username'.")]$Username,
        [Parameter(Mandatory=$true, HelpMessage="Please provide a valid password, example 'MyPassw0rd!'.")]$Password
    )
 
    #Convert the password to a secure string.
    $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
 
    #Convert $Username and $SecurePassword to a credential object.
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$SecurePassword
 
    #Return the credential object.
    Return $Credential
}

#Get all .ASPX pages.
Function Update-SPSiteHeaderLayout
{
    [cmdletbinding()]	
		
    Param
    (
        [Parameter(Mandatory=$true)]$Session,        
        [Parameter(Mandatory=$true)][ValidateSet("Yes","No")]$Subsite
    )        
   

    try{
        $web = Get-PnPWeb -Connection $Session -Includes HeaderLayout
        $web.HeaderLayout = "Minimal"   # Options: Standard, Compact    
        $web.Update()
        Invoke-PnPQuery
        Write-Host "Site: '"$web.Url"' : Header Layout is set to Minimal. IsSubsite : "$Subsite -BackgroundColor Magenta -ForegroundColor White
    }
    catch{
        Write-Host "Site: '"$web.Url"' : Error occured : " $_.Exception.Message -BackgroundColor DarkRed -ForegroundColor White
    }                              
}

# Function executed when site url is passed in CSV files
Function ExecuteSitesFromCSV($siteURLs){
    Foreach ($Site in $siteURLs.URL){
    
        #Connect to the SharePoint environment.
        Write-Host "Connecting to the SharePoint site '"($Site)"'"
        $PNPSession = Connect-PNPOnline -Url $Site -Credentials (Create-PSCredential -Username $SPOServiceUsername -Password $SPOServicePassword) -ReturnConnection
        
        if($PNPSession){       
            #Get all pages.
            Write-Host "Setting Site Header '"($Site)"', please wait"
            Update-SPSiteHeaderLayout -Session $PNPSession -Subsite No 
        
            #Get all subsites.
            $Subsites = Get-PnPSubWebs -Recurse -Connection $PNPSession
        
            #Foreach subsite.
            Foreach($Subsite in $Subsites)
            {
                if($Subsite){
                    Write-Host ""
                    #Connect to the SharePoint subsite.
                    Write-Host "Connecting to the SharePoint subsite '"($SPOServiceRootUrl + $Subsite.ServerRelativeUrl)"'" -BackgroundColor White -ForegroundColor DarkBlue
                    $PNPSessionSubsite = Connect-PNPOnline -Url ($SPOServiceRootUrl + $Subsite.ServerRelativeUrl) -Credentials (Create-PSCredential -Username $SPOServiceUsername -Password $SPOServicePassword) -ReturnConnection
        
                    #Get all pages.
                    Write-Host "Setting Site Header '"($SPOServiceRootUrl + $Subsite.ServerRelativeUrl)"', please wait"
                    Update-SPSiteHeaderLayout -Session $PNPSessionSubsite -Subsite Yes
            
                    #DisConnect to the SharePoint subsite.
                    Write-Host "DisConnecting SharePoint subsite '"($SPOServiceRootUrl + $Subsite.ServerRelativeUrl)"'"
                    Disconnect-PnPOnline -Connection $PNPSessionSubsite
                }
            }
        
            #DisConnect to the SharePoint site.
            Write-Host "DisConnecting SharePoint '"($Site)"'" 
            Disconnect-PnPOnline -Connection $PNPSession
        }
        Write-Host ""            
    }
}

############### Functions - End ###############
#endregion

#region begin main
############### Main - Start ###############

if($IsCSV -eq $true){ 
    $siteURLs = Import-Csv $InputFiles -Header URL
    ExecuteSitesFromCSV($siteURLs)
}
else{                
    #Connect to PnP Online
    Connect-PnPOnline -Url $CollaborationSitesUrl -Credentials (Create-PSCredential -Username $SPOServiceUsername -Password $SPOServicePassword)
  
    #Get All Items from the List in batches
    $ListItems = Get-PnPListItem -List "Sites" -PageSize 1000
    Write-host "Total Number of Items Found:"$ListItems.count
    
    # Disconnect
    Disconnect-PnPOnline

    ForEach ($ListItem in $ListItems) {
        
        $siteURL = $ListItem["ALFA_SiteURL"].Url
        
        try{
            if($siteURL){             
                #Connect to the SharePoint environment
                Write-Host "Connecting to the SharePoint site '"($siteURL)"'"
                $PNPSession = Connect-PNPOnline -Url $siteURL -Credentials (Create-PSCredential -Username $SPOServiceUsername -Password $SPOServicePassword) -ReturnConnection
        
                if($PNPSession){
                    #Get all pages
                    Write-Host "Setting Site Header '"($siteURL)"', please wait"
                    Update-SPSiteHeaderLayout -Session $PNPSession -Subsite No 
            
                    #Get all subsites.
                    $Subsites = Get-PnPSubWebs -Recurse -Connection $PNPSession
        
                    #Foreach subsite.
                    Foreach($Subsite in $Subsites)
                    {
                        if($Subsite){
                            Write-Host ""
                            #Connect to the SharePoint subsite.
                            Write-Host "Connecting to the SharePoint subsite '"($SPOServiceRootUrl + $Subsite.ServerRelativeUrl)"'" -BackgroundColor White -ForegroundColor DarkBlue
                            $PNPSessionSubsite = Connect-PNPOnline -Url ($SPOServiceRootUrl + $Subsite.ServerRelativeUrl) -Credentials (Create-PSCredential -Username $SPOServiceUsername -Password $SPOServicePassword) -ReturnConnection
        
                            #Get all pages.
                            Write-Host "Setting Site Header '"($SPOServiceRootUrl + $Subsite.ServerRelativeUrl)"', please wait"
                            Update-SPSiteHeaderLayout -Session $PNPSessionSubsite -Subsite Yes 
                
                            #DisConnect to the SharePoint subsite.
                            Write-Host "DisConnecting SharePoint subsite '"($SPOServiceRootUrl + $Subsite.ServerRelativeUrl)"'"
                            Disconnect-PnPOnline -Connection $PNPSessionSubsite
                        }
                    }

                    #DisConnect to the SharePoint environment
                    Write-Host "DisConnecting SharePoint site '"($siteURL)"'"
                    Disconnect-PnPOnline -Connection $PNPSession
                }
                Write-Host ""
            }                                           
        }
        catch{
            Write-Host "Error connecting site '"$siteURL"' : " $_.Exception.Message -BackgroundColor DarkRed -ForegroundColor White
            #Disconnect
            Disconnect-PnPOnline -Connection $PNPSession
            Write-Host ""
        }
        #Disconnect
        
    }          
}
############### Main - End ###############
#endregion
