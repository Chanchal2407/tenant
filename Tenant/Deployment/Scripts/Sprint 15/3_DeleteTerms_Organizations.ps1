#
#    Alfa Laval
#    User Story 5878 : Write script to iterate through a Org.csv and perform New, Rename, Deprecate, Move, Merge operation on Organization Hierarchy
#    Task 5906 : Develop "Deprecate" logic
#

# ------------ input variables ------------
# URL for site and credentials for connection
$url = "https://contoso-admin.sharepoint.com/"
$user = "admin@contoso.onmicrosoft.com"
$pssw = 'password' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

$termGroupName = "Share"
$termSetName = "Organizations"

# Download CSV file from User Story [ http://teamtfs.alfalaval.org:8080/tfs/Intranet%20Solutions/Share%20Realization%20Project/_workitems?id=5878 ] and provide path to file
$csvFilePath = "C:\Org_Restructure.csv"


# ------------ process data ------------
# get context
$ctx = Get-PnPContext

# read term GUIDs from CSV
$termGuids = @()
$csv = Get-Content $csvFilePath
for ($i = 1; $i -lt $csv.Count; $i++)
{ 
    $valuesRaw = $csv[$i].Split(';')

    # process only "New" operations
    $operation = $valuesRaw[2]
    if($operation -ne "Deprecate") { continue }

    # add GUID to array
    $termGuids = $termGuids + $valuesRaw[0]
}

# get each term by GUID and depricate if found
foreach ($termGuid in $termGuids)
{
    Write-Host " Term:[" $termGuid "] " -NoNewline
        
    try
    {        
        # Get term by Guid
        $termToDelete = Get-PnPTerm -Identity $termGuid -TermGroup $termGroupName -TermSet $termSetName -ErrorAction SilentlyContinue
        
        # Delete term if exists
        if($termToDelete.Name -ne $null)
        {
            Write-host $termToDelete.Name -NoNewline
            $ctx.Load($termToDelete)
            $termToDelete.DeleteObject()
            $ctx.ExecuteQuery()
            Write-Host " deleted" -f Green
        } else {
            Write-Host "not exists" -f Yellow
        }
    } catch {
        Write-Host " -- ERROR-1 : Exception -->> " $_.Exception.Message -f Red
    }

}


Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "