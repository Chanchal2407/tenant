#
#    Alfa Laval
#    User Story 5878 : Write script to iterate through a Org.csv and perform New, Rename, Deprecate, Move, Merge operation on Organization Hierarchy
#    Task 5907 : Develop "Rename" logic
#

# ------------ input variables ------------
# URL for site and credentials for connection
$url = "https://contoso-admin.sharepoint.com/"
$user = "admin@contoso.onmicrosoft.com"
$pssw = 'password' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

# Download CSV file from User Story [ http://teamtfs.alfalaval.org:8080/tfs/Intranet%20Solutions/Share%20Realization%20Project/_workitems?id=5878 ] and provide path to file
$csvFilePath = "C:\Org_Restructure.csv"

$termGroupName = "Share"
$termSetName = "Organizations"


# ------------ process data ------------
# setup the context
$ctx = Get-PnPContext
# Get TermSet "Categories"
$taxonomySession = Get-PnPTaxonomySession -ErrorAction Stop
$taxonomySession.UpdateCache()
$termSet = $taxonomySession.GetTermSetsByName($termSetName,1033)
$ctx.Load($termSet)
$ctx.ExecuteQuery()

# read term GUIDs from CSV
$csv = Get-Content $csvFilePath
for ($i = 1; $i -lt $csv.Count; $i++)
{ 
    $valuesRaw = $csv[$i].Split(';')

    $guid = $valuesRaw[0]
    $nameOld = $valuesRaw[3]
    $nameNew = $valuesRaw[4]

    # process only "Rename" operations
    $operation = $valuesRaw[2]
    if($operation -ne "Rename") { continue }

    Write-Host ""
    Write-Host " Term:[" $nameOld "] "
    
    try
    {
        # get term
        $term = Get-PnPTerm -Identity $guid -TermSet $termSetName -TermGroup $termGroupName -Recursive -ErrorAction Ignore
        if($term -ne $null)
        {   
            if($term.Name -eq $nameNew)
            {
                Write-Host "   OK-1: existing term already have new name [ $guid | " $term.Name "== $nameNew ]" -f Yellow
                continue
            }

            #check if any siblings already have new name 
            $siblings = $term.Parent.Terms
            $ctx.Load($siblings)
            $ctx.ExecuteQuery()

            $siblingWithNewName = $siblings | ? {$_.Name -eq $nameNew} 
            if($siblingWithNewName -ne $null)
            {
                Write-Host "---ERROR-3 : other term with new name already exists [" $siblingWithNewName[0].Id.Guid "|" $siblingWithNewName[0].Name "]" -f Red
                continue
            }

            $nameOld = $term.Name
            $term.Name = $nameNew
            $term.TermStore.CommitAll()
            
            $termNew = Get-PnPTerm -Identity $guid -TermSet $termSetName -TermGroup $termGroupName -Recursive
            Write-Host "   OK-2: term name updated [ $guid | $nameOld -->> $nameNew ]" -f Green
        }
        else
        {
            Write-Host "---ERROR-2 : term not found [ $guid | $nameOld ]"
        }
        
    }
    catch [System.Exception]
    {
        Write-Host "ERROR-1 : Exception -->> " $_.Exception
    }
}

Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "