#
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

# Provide path to output file location - it is create by script "Export_NewsMetadata.ps1"
$inputPath = "C:\T5957_metadata.txt"
$libName = "Site Pages"

# ------------ process data ------------
Write-host "Site: $url" 

# set up context
$ctx = Get-PnPContext

# get list
$list = $ctx.web.Lists.GetByTitle($libName)
$ctx.Load($list)
$ctx.ExecuteQuery()

# get field "Locations"
$fieldLoc = $list.Fields.GetByInternalNameOrTitle("Locations")
$ctx.Load($fieldLoc)
$ctx.ExecuteQuery()
$taxFieldLoc = [Microsoft.SharePoint.Client.ClientContext].GetMethod("CastTo").MakeGenericMethod([Microsoft.SharePoint.Client.Taxonomy.TaxonomyField]).Invoke($ctx, $fieldLoc)
# get field "Organizations"
$fieldOrg = $list.Fields.GetByInternalNameOrTitle("Organizations")
$ctx.Load($fieldOrg)
$ctx.ExecuteQuery()
$taxFieldOrg = [Microsoft.SharePoint.Client.ClientContext].GetMethod("CastTo").MakeGenericMethod([Microsoft.SharePoint.Client.Taxonomy.TaxonomyField]).Invoke($ctx, $fieldOrg)

# iterate through each input entry
$inputLines = Get-Content $inputPath
foreach($inputLine in $inputLines)
{
    try
    {
        # clear output variable
        $message = $null

        # read values from input metadata line
        $inputRaw = $inputLine.Split(';')
        $id = $inputRaw[0]
        $title = $inputRaw[1]
        $fieldName = $inputRaw[2]
        $fieldValues = $inputRaw[3]

        # get item
        $item = Get-PnPListItem -Id $id -List $libName
        if($item -ne $null)
        {
            Write-Host "Page [" $item.Id "|" $item["Title"] "]"

            # format new taxonomy field value
            $valuesFromInput = $fieldValues.Split('#')
            if($valuesFromInput.Count -ne 0 -and $valuesFromInput[0].Length -ne 0)
            {
                # get original locations/organizations values and update                
                $valueOriginal = ""
                $arrayItems = $item[$fieldName]
                if($arrayItems.Count -ne 0)
                { 
                    foreach($arrayItem in $arrayItems) { $valueOriginal +=  $arrayItem.Label + "|" + $arrayItem.TermGuid + "#" }
                    $valueOriginal = $valueOriginal.Substring(0,$valueOriginal.Length-1)
                }

                # format new tax field values
                $termValues = @();
                foreach($termValue in $valuesFromInput) 
                {
                    $termValues += "-1;#" + $termValue; 
                    $termValuesString = $termValues -join ";#"
                }

                # parse previously format values 
                if($fieldName -eq "ShareLocations") 
                { 
                    $fieldValuesLoc = New-Object Microsoft.SharePoint.Client.Taxonomy.TaxonomyFieldValueCollection($ctx, $termValuesString, $taxFieldLoc)
                    $taxFieldLoc.SetFieldValueByValueCollection($item, $fieldValuesLoc) 
                }
                if($fieldName -eq "ShareOrganizations") 
                { 
                    $fieldValuesOrg = New-Object Microsoft.SharePoint.Client.Taxonomy.TaxonomyFieldValueCollection($ctx, $termValuesString, $taxFieldOrg)
                    $taxFieldOrg.SetFieldValueByValueCollection($item, $fieldValuesOrg) 
                }
                
                # update item
                $item.SystemUpdate()
                
                # push changes to SPO
                $ctx.Load($item)
                $ctx.ExecuteQuery()

                Write-host "  OK-1 : Page field [$fieldName] updated [$valueOriginal] -->> [$fieldValues]" -f Green
            }
            else{ Write-host "--  OK-2 : Term field [$fieldName]  empty in source file" -f Yellow }
        }
        else { Write-host "--- ERROR-2 : page not found [ $id | $title ]" -f Red }
    }
    catch [System.Exception]
    {
        Write-host "--- ERROR-1 : Unknown exception" $_.Exception -f Red
    } 
}

Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "