####
#    Alfa Laval
#    Task 5957 : Create script to export and import news page metadata
#

# ------------ input variables ------------
# URL for site and credentials for connection
$url = "https://contoso-admin.sharepoint.com"
$user = "admin@contoso.onmicrosoft.com"
$pssw = 'password' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

# Provide path to output file location
$output = "C:\T5957_metadata.txt"


# ------------ process data ------------
Write-host "Site: $url" 

# setup the context
$ctx = Get-PnPContext

# get all list items
$items = Get-PnPListItem -List "Site Pages"
Write-host " Items [" $items.Count "]"

# iterate through all library items
foreach($item in $items)
{
    try
    {
        # clear output variable
        $message = $null

        # get locations and format output string
        $locsString = ""
        $locs = $item["ShareLocations"]
        if($locs.Count -ne 0)
        {
            foreach($loc in $locs) { $locsString += $loc.Label + "|" + $loc.TermGuid + "#" }
            $locsString = $locsString.Substring(0,$locsString.Length-1)
        }
        $message += $item.Id.ToString() +";"+ $item["Title"] +";ShareLocations;"+ $locsString

        # get organizations and format output string
        $orgsString = ""
        $orgs = $item["ShareOrganizations"]
        if($orgs.Count -ne 0)
        {
            foreach($org in $orgs) { $orgsString += $org.Label + "|" + $org.TermGuid + "#" }
            $orgsString = $orgsString.Substring(0,$orgsString.Length-1)
        }
        $message += [Environment]::NewLine + $item.Id.ToString() +";"+ $item["Title"] +";ShareOrganizations;"+ $orgsString
    }
    catch [System.Exception]
    {
        $message += [Environment]::NewLine + "ERROR-1 : Unknown exception" + $_.Exception + [Environment]::NewLine
    }
    finally
    {
        # output format : [ID];[Title];[Field];[Values]
        $message | Out-File $output -Append

        Write-host $message
    }   
}

Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "