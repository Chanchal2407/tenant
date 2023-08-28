####
#    Alfa Laval
#    Task 6012 : Create a Powershell script to process org pages
#    User Story 5994 : Create a Powershell script to iterate through csv file and create Pages, set page properties and create folder in document library
####
#
#   Script adds users to site build-in "Members" group
#
####


# ------------ input variables ------------
# URL for site and credentials for connection
$url = "https://contoso.sharepoint.com/sites/target-site/"
$user = "admin@contoso.onmicrosoft.com"
$pssw = 'password' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

# Provide path to file that contains list of users
$csvFilePath = "C:\users.csv"


# ------------ process data ------------
Write-host "Site: " $url

# read data from CSV
$csv = Get-Content $csvFilePath
Write-host "CSV contains [" ($csv.Length-1) "] entries "

# get SP group
$webTitle = $(Get-PnPWeb -Includes Title | Select Title).Title
$groupName = "$webTitle Members"

for ($i = 0; $i -lt $csv.Count; $i++)
{ 
    $valuesRaw = $csv[$i].Split(';')
    $userEmail = $valuesRaw[0].Trim()

    try
    {
        Add-PnPUserToGroup -LoginName $userEmail -Identity $groupName
        Write-host "OK : $userEmail"
    }
    catch [System.Exception]
    {
        #Write-Host "--- ERROR-1 : Exception : " $_.Exception -f Red
    }
}
   
Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "