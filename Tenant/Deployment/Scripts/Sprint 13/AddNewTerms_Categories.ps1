#
#    Alfa Laval
#    Task 5778 : Script to iterate through "Region_Location_Amalysis_20190308.csv", create new term under Category termset based on "NewTerm" property in csv file
#

# ------------ input variables ------------
# URL for site and credentials for connection
$url = "https://contoso-admin.sharepoint.com/"
$user = "admin@contoso.onmicrosoft.com"
$pssw = 'password' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

$termGroupName = "Share"
$termSetName = "Categories"

# Download CSV file from Task [http://teamtfs.alfalaval.org:8080/tfs/Intranet%20Solutions/Share%20Realization%20Project/_workitems?id=5778] and provide path to file
$csvFilePath = "C:\Regions_Location_Analysis_20190308.csv"

# ------------ process data ------------
# read term GUIDs from CSV
$ctx = Get-PnPContext

$csv = Get-Content $csvFilePath
for ($i = 1; $i -lt $csv.Count; $i++)
{ 
    $valuesRaw = $csv[$i].Split(';')

    $newName = $valuesRaw[2]
    $newGuid = $valuesRaw[3]

    Write-host ""
    Write-Host " Term:[" $newName "//" $newGuid "] "
    
    try
    {
        #-------- TERM CREATION --------
        # parent term - all existing terms are subterms (children)
        $termSetParent = Get-PnPTermSet -Identity $termSetName -TermGroup $termGroupName 
        $ctx.Load($termSetParent.Terms)
        $ctx.ExecuteQuery()
        $termParent = $termSetParent.Terms[0]

        # check if term already exists
        $term1 = Get-PnPTerm -Identity $newName -TermSet $termSetName -TermGroup $termGroupName -Recursive -ErrorAction Ignore 
        if($term1 -ne $null)
        {
            Write-Host " -- ERROR-1 : term with new name already exists" -f Yellow
        }
        else
        {
            # create term
            $newTerm = $termParent.CreateTerm($newName, 1033, $newGuid) 
            $newTerm.CreateLabel($newGuid,1033, $false) | out-null
            
            $newTerm = Get-PnPTerm -Identity $newGuid -TermSet $termSetName -TermGroup $termGroupName -Recursive
            Write-Host " -- OK: new term created [" $termParent.Name "-->>" $newTerm.Name "//" $newTerm.Id.Guid "]" -f Green

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