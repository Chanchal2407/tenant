#
#    Alfa Laval
#    User Story 5878 : Write script to iterate through a Org.csv and perform New, Rename, Deprecate, Move, Merge operation on Organization Hierarchy
#    Task 5905 : Develop "New" logic
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

$currentLevel = 0
$lastLevel = 1

# read term GUIDs from CSV
$csv = Get-Content $csvFilePath

do
{
    Write-Host ""
    Write-Host "----- Proceed with Level $currentLevel -----" -ForegroundColor Green
    Write-Host ""

    # Get TermSet "Categories"
    $taxonomySession = Get-PnPTaxonomySession -ErrorAction Stop
    $taxonomySession.UpdateCache()

    # Get TermSet "Organizations"
    $termSet = Get-PnPTermSet -Identity $termSetName -TermGroup $termGroupName 
    $ctx.Load($termSet.Terms)
    $ctx.ExecuteQuery()

    # Get root term
    $rootTerm = $termSet.Terms[0]
    $ctx.Load($rootTerm)
    $ctx.ExecuteQuery()

    for ($i = 1; $i -lt $csv.Count; $i++)
    { 
        $valuesRaw = $csv[$i].Split(';')

        # values for new term
        $newGuid = New-Guid
        $label = $valuesRaw[3].Trim()
        $path = $valuesRaw[6]

        # process only "New" operations
        $operation = $valuesRaw[2]
        if($operation -ne "New") { continue }
    	    
        # get all parents and trim whitespace
        $parents = $path.Split(">").Trim()
        
        # remove first and second parent (they are not needed) and last one (that is new term itself)
        $parents = $parents[2..($parents.Count-2)]
        $parentsPath = "Organizations  > " + ($parents -join " > ")

        # set last level
        $lastLevel = ($lastLevel,$parents.Count|Measure-Object -Maximum).Maximum

        # proceed with current level only
        if ($parents.Count -ne $currentLevel) { continue }

        Write-Host ""
        Write-Host " Term:[ $label ] row $i"

        try
        {
            # check if all parent terms exist
            $parentAbove = $rootTerm
            foreach($parent in $parents)
            {
                $parentTerms = $parentAbove.Terms
                $ctx.Load($parentTerms)
                $ctx.ExecuteQuery()

                $parentAbove = $parentTerms | ? {$_.Name -eq $parent}
                if($parentAbove -eq $null)
                {
                    Write-Host "--- ERROR-2 : cannot create new term, missing parent [ $parent ] in path [ $parentsPath ]" -f Yellow
                    break
                }
            }
            if($parentAbove -eq $null) { continue }

            # check if last parent already contains term with new name
            $childTerms = $parentAbove.Terms
            $ctx.Load($childTerms)
            $ctx.ExecuteQuery()
            $termExisting = $childTerms | ? {$_.Name -eq $label}
            if($termExisting -ne $null)
            {
                Write-Host "--- ERROR-3 : other term with new NAME already exists [" $termExisting.Id.Guid "|" $termExisting.Name "]" -f Yellow
                continue
            }
        
            # create new term
            $newTerm = $parentAbove.CreateTerm($label, 1033, $newGuid)
            $newTerm.CreateLabel($newGuid.Guid, 1033, $false) | Out-Null
        
            # validate creation
            $newTerm = Get-PnPTerm -Identity $newGuid -TermSet $termSetName -TermGroup $termGroupName -Recursive
            Write-Host "    OK: new term created [" $newTerm.Id.Guid "|" $newTerm.Name "] under [ $parentsPath ] " -f Green
        }
        catch [System.Exception]
        {
            Write-Host "--- ERROR-1 : Exception : " $_.Exception -f Red
        }
    }
    $currentLevel++
} while ($currentLevel -le $lastLevel)

Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "