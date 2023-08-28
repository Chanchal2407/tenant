#
#    Alfa Laval
#    Task 5939 : Create PowerShell script to update User Profile Topics property
#    User Story 5921 : Similar to U.S 5751, Update User subscription of attached user with responsive new term in User profile subscription
#

# ------------ input variables ------------
# URL for site and credentials for connection
$url = "https://contoso-admin.sharepoint.com/"
$user = "admin@contoso.onmicrosoft.com"
$pssw = 'password' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

$termSetName = "Locations"

# Provide path to output file location
$output = "C:\T5939_output.txt"

# download CSV file from User Story [http://teamtfs.alfalaval.org:8080/tfs/Intranet%20Solutions/Share%20Realization%20Project/_workitems?id=5921] 
# and provide path to file
$csvFilePath = "C:\LocationDivided.csv"


# ------------ process data ------------
# setup the context
$ctx = Get-PnPContext

$taxonomySession = Get-PnPTaxonomySession -ErrorAction Stop
$taxonomySession.UpdateCache()

# Get TermSet "Locations"
$termSet = $taxonomySession.GetTermSetsByName($termSetName,1033)
$termSet.Context.Load($termSet)
$termSet.Context.ExecuteQuery()

# Get all 1st level terms
$terms1lvl = $termSet[0].Terms
$terms1lvl.Context.Load($terms1lvl)
$terms1lvl.Context.ExecuteQuery()

# Get root term and all child terms
$rootTerm = $terms1lvl[0]
$terms = $rootTerm.Terms
$terms.context.Load($terms)
$terms.context.ExecuteQuery()

# iterate through CSV
$csv = Get-Content $csvFilePath
for ($i = 1; $i -lt $csv.Count; $i++)
{ 
    $valuesRaw = $csv[$i].Split(';')

    # values for new term
    $userEmail = $valuesRaw[0].Trim()
    $locPathsNew = $valuesRaw[2].Split('#')

    $message = [Environment]::NewLine + " User:[ $userEmail ]"
    try
    {
        $user = Submit-PnPSearchQuery -Query "WorkEmail:$userEmail" -SourceId "B09A7990-05EA-4AF9-81EF-EDFAB16C4E31" -RelevantResults
        if($user -eq $null)
        { 
            $message = $message + [Environment]::NewLine + "--- ERROR-2 : user not found"
        }
        else
        {
            # get all properties and checks if "Topic" and "Topic IDs" exist
            $upp = Get-PnPUserProfileProperty -Account $user.AccountName
            if($upp.UserProfileProperties -ne $null -AND $upp.UserProfileProperties.ContainsKey("ShareTopics") -AND $upp.UserProfileProperties.ContainsKey("ShareTopicsIDs"))
            {
                # these fields could contain multiple values
                $userTermNamesOriginal = $upp.UserProfileProperties.Item("ShareTopics").Split('|')
                $userTermIdsOriginal = $upp.UserProfileProperties.Item("ShareTopicsIDs").Split('|')

                # create new termprary arrays to add'n'remove terms, will store all values and be inserted into SP user properties
                $userTermNames = $userTermNamesOriginal
                $userTermIds = $userTermIdsOriginal

                # both properties might contain one array item with zero lenght
                if($userTermNames.Count -eq 1 -and $userTermNames[0].Length -eq 0) { $userTermNames = ""; $userTermIds = ""; }
                if($userTermIds.Count -eq 1 -and $userTermIds[0].Length -eq 0) { $userTermNames = ""; $userTermIds = ""; }

                # both arrays MUST be with same count - if not, then there is something terribly wrong
                if($userTermNames.Count -ne $userTermIds.Count)
                {
                    $message = $message + [Environment]::NewLine + "  ERROR-3 : Arrays in user properties [Topics] and [TopicIDs] have uneven count"
                    continue
                }

                # print original values
                $originalNames = $userTermNames -join " ; "
                $message = $message + [Environment]::NewLine + "   Original : " + $originalNames 
                $originalIds = $userTermIds -join " ; "
                $message = $message + [Environment]::NewLine + "   Original : " + $originalIds 

                # add each new term to term array
                foreach($locPathNew in $locPathsNew)
                {
                    # get parents and trim whitespace
                    $parents = $locPathNew.Split('>')
                    for ($j = 0; $j -lt $parents.Count; $j++) { $parents[$j] = $parents[$j].Trim() }    
                    
                    # format full path for logging
                    $parentsPath = "$termSetName > " + ($parents -join " > ")

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
                            $message = $message + [Environment]::NewLine + "--- ERROR-4 : cannot get new term, missing parent [ $parent ] in path [ $parentsPath ]"
                            break
                        }
                    }
                    if($parentAbove -eq $null) { continue }

                     # last parent is term it self
                    $term = $parentAbove
                                       
                    # "add" new variables (PS consider single-item arrays as simple strings - need to build a new array)
                    if($userTermNames.Count -eq 1)
                    {
                        $userTermNames = @($userTermNames[0],$term.Name)
                        $userTermIds = @($userTermIds[0],$term.Id.Guid)
                    }
                    else
                    {
                        $userTermNames = $userTermNames + $term.Name
                        $userTermIds = $userTermIds + $term.Id.Guid
                    }
                }

                # print new values
                $updatedName = $userTermNames -join " ; "
                $message = $message + [Environment]::NewLine + "   New values : " + $updatedName 
                $updatedIds = $userTermIds -join " ; "
                $message = $message + [Environment]::NewLine + "   New values : " + $updatedIds 
                
                # update user properties
                Set-PnPUserProfileProperty -Account $user.AccountName -PropertyName "ShareTopics" -Values $userTermNames
                Set-PnPUserProfileProperty -Account $user.AccountName -PropertyName "ShareTopicsIDs" -Values $userTermIds

                $message = $message + [Environment]::NewLine + " OK : User profile properties updated for user [" + $user.AccountName + "]"
            }
            else
            {
                $message = $message + [Environment]::NewLine + "--- ERROR-5 : Properties [Topics] and/or [TopicIDs] not found"
            }
        }
    }
    catch [System.Exception]
    {
        $message = $message + [Environment]::NewLine + "--- ERROR-1 : Exception : " + $_.Exception
    }
    finally
    {
        Write-host $message
	    $message | Out-File $output -Append
    }
}

Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "