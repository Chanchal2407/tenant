#
#    Alfa Laval
#    User Story 6237 : About Me Page footer and CLC implementation - Extract and send excel to Annika to fill it
#


# ------------ input variables ------------
# URL for site and credentials for connection
$url = "https://alfalavalonline.sharepoint.com/sites/share/aboutme/sweden/"
$user = "Kristaps.Vilerts_a@alfalaval.com"
$pssw = 'Krvise@12345' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

# Provide path to output file location
$output = "C:\US6237_pageInfo_sweden.txt"


# ------------ process data ------------

# 1 # Root "AboutMe" site
$items = Get-PnPListItem -List "Site Pages"
Write-host "Root site '/aboutme' pages count:" $items.Count
foreach($item in $items)
{
    try
    {
        # clear output variable
        $message = $null
        $message = $item.Id.ToString() +";"+ $item["Title"] +";" + $url + ";" + "https://alfalavalonline.sharepoint.com" + $item.FieldValues.FileRef
    }
    catch [System.Exception]
    {
        $message += [Environment]::NewLine + "ERROR : Unknown exception" + $_.Exception + [Environment]::NewLine
    }
    finally
    {
        # output format : [ID];[Title];[PageUrl];[SiteUrl]
        $message | Out-File $output -Append

        Write-host $message
    }   
}


$sites = Get-PnPSubWebs
$sites.Count


Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "