#
#    Alfa Laval
#    Task 5776 : script to Iterate through "New_Location_analysis20190308.csv" and create new term by Name Property under Location termset
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

# Download CSV file from Task [http://teamtfs.alfalaval.org:8080/tfs/Intranet%20Solutions/Share%20Realization%20Project/_workitems?id=5776] and provide path to file
$csvFilePath = "C:\New_Locations_Analysis_20190308.csv"



# ------------ process data ------------
$ctx = Get-PnPContext

# read term GUIDs from CSV
$csv = Get-Content $csvFilePath
for ($i = 1; $i -lt $csv.Count; $i++)
{ 
    $valuesRaw = $csv[$i].Split(';')

    $nameParent = $valuesRaw[2].Split('>')[0].Trim()
    $nameChild = $valuesRaw[2].Split('>')[1].Trim()
    $type = $valuesRaw[3]

    Write-host ""
    Write-Host " Term:[" $nameChild "] "
    
    try
    {
        # search for parent - if exists, proceed with child // if not found, then error (not covered)
        $termParent = Get-PnPTerm -Identity $nameParent -TermSet $termSet -TermGroup $termGroup -Recursive -ErrorAction Ignore 

        # added case for second level term creation
        if($type -eq "Country") { $termParent = Get-PnPTerm -Identity $nameParent -TermSet $termSet -TermGroup $termGroup -ErrorAction Ignore  }

        if($termParent -ne $null)
        {
            $ctx.Load($termParent.Terms)
            $ctx.ExecuteQuery()

            # search for child - if not found create new
            $termChild = $termParent.Terms | ? {$_.Name -eq $nameChild}
            if($termChild -eq $null)
            {
                $newGuid = New-Guid
                $newTerm = $termParent.CreateTerm($nameChild, 1033, $newGuid)
                $newTerm.CreateLabel($newGuid.Guid, 1033, $false) | out-null

                $newTerm = Get-PnPTerm -Identity $newGuid -TermSet $termSet -TermGroup $termGroup -Recursive
                Write-Host " -- OK-1: new term created [" $nameParent "-->>" $newTerm.Name "//" $newTerm.Id.Guid "]" -f Green
            }
            else
            {
                Write-Host " -- OK-2 : child exists [" $nameParent "-->>" $termChild.Name "//" $termChild.Id.Guid "]" -f Yellow
            }
            
        }
        else
        {
            Write-Host " -- ERROR-2 : parent not found" -f Red
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