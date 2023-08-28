#
#    Alfa Laval
#    Task 5777 : Script to iterate through "Update_Location_Analysis_20190308.csv",get term by TermGuid and Update Term Label based on "ChangedName" property
#

# ------------ input variables ------------
# URL for site and credentials for connection
$url = "https://contoso-admin.sharepoint.com/"
$user = "admin@contoso.onmicrosoft.com"
$pssw = 'password' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

$termGroup = "Share"
$termSet = "Locations"

# Download CSV file from Task [http://teamtfs.alfalaval.org:8080/tfs/Intranet%20Solutions/Share%20Realization%20Project/_workitems?id=5777] and provide path to file
$csvFilePath = "C:\Update_Locations_Analysis_20190308.csv"



# ------------ process data ------------
# read term GUIDs from CSV
$csv = Get-Content $csvFilePath
for ($i = 1; $i -lt $csv.Count; $i++)
{ 
    $valuesRaw = $csv[$i].Split(';')

    $guidParent = $valuesRaw[1].Split('>')[0].Trim()
    $guidChild = $valuesRaw[1].Split('>')[1].Trim()

    $nameOld = $valuesRaw[0]
    $nameNew = $valuesRaw[2]

    Write-Host ""
    Write-Host " Term:[" $nameOld "] "
    
    try
    {
        # search for term
        $term = Get-PnPTerm -Identity $guidChild -TermSet $termSet -TermGroup $termGroup -Recursive -ErrorAction Ignore 
        if($term -ne $null)
        {   
            if($term.Name -eq $nameNew)
            {
                Write-Host " -- OK-1: term name matches [" $nameNew "-->>" $term.Name "//" $guidChild "]" -f Green
                continue
            }

            #check if term with new name already exists (so opertion cannot be executed)
            $termExisting = Get-PnPTerm -Identity $nameNew -TermSet $termSet -TermGroup $termGroup -Recursive -ErrorAction Ignore
            if($termExisting -ne $null)
            {
                Write-Host " -- ERROR-3 : term with new name already exists [" $nameNew "]" -f Yellow
                continue
            }

            $term.Name = $nameNew
            $term.TermStore.CommitAll()

            $termNew = Get-PnPTerm -Identity $guidChild -TermSet $termSet -TermGroup $termGroup -Recursive -ErrorAction Ignore

            Write-Host " -- OK-2: term name update [" $nameOld "-->>" $termNew.Name "//" $guidChild "]" -f Green
        }
        else
        {
            Write-Host " -- ERROR-2 : term not found [" $guidChild "]" -f Red
        }
        
    }
    catch [System.Exception]
    {
        Write-Host "ERROR-1 : Exception !!!" -f Red
    }
}

Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "