#This Script will export Members of SharePoint and Active Directory Group of given SharePoint Site

[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client")
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime")
#Finding the script path
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
#Reading the site url from console...
$siteUrl = Read-Host -Prompt "Enter SharePoint Site URL"
#CSV paths
$exportFile = "$scriptPath\export-grp.csv"
#Reading Admin username and password
$username = Read-Host -Prompt "Enter Admin Username" 
$password = Read-Host -Prompt "Enter Admin password" -AsSecureString
#credential object for AD Connection
$cred = New-Object System.Management.Automation.PSCredential($username, $password)
[System.Management.Automation.PSCredential]$PSCredentials = New-Object System.Management.Automation.PSCredential($username, $password)




#Connect to PnP Online
Write-host "Connecting to Site to fetch SharePoint Groups..." -ForegroundColor Green
Connect-PnPOnline -Url $SiteURL -Credentials $PSCredentials
 
#Get All Groups from Site - Exclude system Groups
$Groups = Get-PnPGroup | Where-Object { $_.OwnerTitle -ne "System Account" }
$GroupData = @()
 
#Get Group Details
ForEach ($Group in $Groups) {
    #Get Group data
    $GroupData += New-Object PSObject -Property ([ordered]@{
            "Group Name" = $Group.Title
            "Users"      = $Group.Users.Title -join ";"
            "Group Type" = "SharePoint Group"
        })
}
Write-host "Exporting the SharePoint Group data to Excel..." -ForegroundColor Green
 
#Export Users data to CSV file
$GroupData | Export-Csv -NoTypeInformation $exportFile
 
#The Client ID from App Registrations
$clientId = "ad1a97cf-acbc-48c0-a55f-b69d7f4226b2"
 
#The Tenant ID from App Registrations
$tenantId = "ed5d5f47-52dd-48af-90ca-f7bd83624eb9"
 
#The Client ID from certificates and secrets section
$clientSecret = '4Hn9gePX10_OimqtKIp?b:.OA@h:lrVl'
# Construct the authentication URL
$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
 
# Construct the body to be used in Invoke-WebRequest
$body = @{
    client_id     = $clientId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}
 
# Get Authentication Token
$tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
 
# Extract the Access Token
$token = ($tokenRequest.Content | ConvertFrom-Json).access_token

#$Credentials =Get-Credential
Write-host "Connecting to Active Directory..." -ForegroundColor Green
Connect-AzureAD -TenantId "ed5d5f47-52dd-48af-90ca-f7bd83624eb9" -Credential $cred
$tempsite=$siteUrl.Replace("https://alfalavalonline.sharepoint.com" ,"")

$SiteIDURI ="https://graph.microsoft.com/v1.0/sites/alfalavalonline.sharepoint.com:$tempsite?$select=id"
$method = "GET"
$siteIDOutput = Invoke-WebRequest -Method $method -Uri $SiteIDURI -ContentType "application/json" -Headers @{Authorization = "Bearer $token" } -ErrorAction Stop
$siteIDdata = $siteIDOutput.Content | ConvertFrom-Json
if($null -ne $siteIDdata){
    $siteID=$siteIDdata.id.Split(",")[1];
}
#The Graph API URL
$uri = "https://graph.microsoft.com/v1.0/sites/$siteID/lists/User Information List/items?expand=fields"
 
$method = "GET"
 
# Run the Graph API query to retrieve users
$output = Invoke-WebRequest -Method $method -Uri $uri -ContentType "application/json" -Headers @{Authorization = "Bearer $token" } -ErrorAction Stop
$data = $output.Content | ConvertFrom-Json
Write-host "Looking for AD groups..." -ForegroundColor Green
$ADGroupData = @()
$data.value | ForEach-Object { 
   
    $ctype = $_.contentType
  
    If ($ctype.name -eq "DomainGroup") {
        #Write-Host $_.fields.LinkTitle $ctype.name $_.id 
        $groupTitle = $_.fields.LinkTitle
        $adg = Get-AzureADGroup -Filter "DisplayName eq '$groupTitle'"
        if ($adg -ne $null) {
            $temp = Get-AzureADGroupMember -ObjectId $adg.ObjectId
            $adusers = ""
            $temp | ForEach-Object {
                $adusers += $_.DisplayName+";";
            }
            $ADGroupData += New-Object PSObject -Property ([ordered]@{
                    "Group Name" = $groupTitle
                    "Users"      = $adusers
                    "Group Type" = "AD Group"
                })

   

        }

    }

    
}
Write-Host "Exporting the data csv.." -ForegroundColor Green
#Export Users data to CSV file
$ADGroupData | Export-Csv -NoTypeInformation $exportFile -Append
Disconnect-AzureAD
Disconnect-PnPOnline
Write-Host "Export Completed" -ForegroundColor Green

