#
#    Alfa Laval
#    Task 5775 : script to iterate through "Deprecate_Locations_Anaysis_20190308.csv" and based on GuidPath column and Deprecate the term
#

# ------------ input variables ------------
# URL for site and credentials for connection
$url = "https://contoso-admin.sharepoint.com/"
$user = "admin@contoso.onmicrosoft.com"
$pssw = 'password' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

$termSetName = "Locations"

# Download CSV file from Task [http://teamtfs.alfalaval.org:8080/tfs/Intranet%20Solutions/Share%20Realization%20Project/_workitems?id=5775] and provide path to file
$csvFilePath = "C:\Deprecate_Locations_Anaysis_20190308.csv"


# ------------ process data ------------
# read term GUIDs from CSV
$termGuids = @()
$csv = Get-Content $csvFilePath
for ($i = 1; $i -lt $csv.Count; $i++)
{ 
    $valuesRaw = $csv[$i].Split(';')

    $guid = $valuesRaw[5].Split('>')[1].Trim()
    $termGuids = $termGuids + $guid
}

# get context
$ctx = Get-PnPContext

$taxonomySession = Get-PnPTaxonomySession -ErrorAction Stop
$taxonomySession.UpdateCache()

# Get TermSet "Locations"
$termSet = $taxonomySession.GetTermSetsByName($termSetName,1033)
$ctx.Load($termSet)
$ctx.ExecuteQuery()

# Get all 1st level terms
$terms1lvl = $termSet[0].Terms
$ctx.Load($terms1lvl)
$ctx.ExecuteQuery()

# Get root term and all child terms
$rootTerm = $terms1lvl[0]
$terms = $rootTerm.Terms
$ctx.Load($terms)
$ctx.ExecuteQuery()

# get each term by GUID and depricate if found
try
{
    foreach ($termGuid in $termGuids)
    {
        Write-host ""
        Write-Host " Term:[" $termGuid "] "-NoNewline

        # search for term
        $termToDelete = Get-PnPTerm -Identity $termGuid -TermSet $termSetName -TermGroup $termGroup -Recursive -ErrorAction SilentlyContinue 
        if($termToDelete -eq $null) { $termToDelete = Get-PnPTerm -Identity $termGuid -TermSet $termSet -TermGroup $termGroup -ErrorAction SilentlyContinue  }
        if($termToDelete -ne $null)
        {
            $ctx.Load($termToDelete)
            $ctx.ExecuteQuery()

            $termToDelete.DeleteObject()

            $terms = $rootTerm.Terms
            $ctx.Load($terms)
            $ctx.ExecuteQuery()
            Write-Host " --  OK-1 deleted:[" $termToDelete.Name "]" -f Green
        }
        else { Write-Host " --  ERROR-2 : term not founf " -f Yellow } 
    }
}
catch [System.Exception]
{
    Write-Host " -- ERROR-1 : Exception -->> " $_.Exception.Message -f Red
}

    
Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "