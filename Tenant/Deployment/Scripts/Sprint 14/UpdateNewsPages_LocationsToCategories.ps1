
# ------------ input variables ------------
$url = "https://contoso-admin.sharepoint.com"
$user = "admin@contoso.onmicrosoft.com"
$pssw = 'password' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

$termGroup = "Share"
$termSetCatName = "Categories"
$libName = "SitePages"

$whitelist = @("Adriatic (Sales Company)","Benelux","Central Europe","Chile and Peru","ColVenPa","Iberica","Middle East","MidEurope","Nordic","Oceania","PARC (Peru, Argentina and Chile)","Poland and Baltics","South East Asia","South East Europe")


# ------------ process data ------------
# Setup the context
$ctx = Get-PnPContext

$taxonomySession = Get-PnPTaxonomySession -ErrorAction Stop
$taxonomySession.UpdateCache()

# Get TermSet "Categories"
$termSetCat = $taxonomySession.GetTermSetsByName($termSetCatName,1033)
$ctx.Load($termSetCat)
$ctx.ExecuteQuery()

#Get the Categories field to update
$field = Get-PnPField -List $libName -Identity "ShareCategories"
$ctx.Load($field)
$ctx.ExecuteQuery()
$taxField = [Microsoft.SharePoint.Client.ClientContext].GetMethod("CastTo").MakeGenericMethod([Microsoft.SharePoint.Client.Taxonomy.TaxonomyField]).Invoke($ctx, $field)

#Go through each term in Locations
foreach($termInList in $whiteList)
{
    Write-host " Term (LOC from list) : " $termInList -NoNewline

    # Get pages with specific term
    $query = "<View Scope=""RecursiveAll""><Query><Where><Contains><FieldRef Name='ShareLocations'/><Value Type='Text'>" + $termInList + "</Value></Contains></Where></Query></View>"
    $items = Get-PnPListItem -List $libName -Query $query
    Write-host " [" $items.Count "]"

    # Related term in Categories must be created - otherwise cannot update page with new value
    $termCat = Get-PnPTerm -Identity $termInList -TermSet $termSetCatName -TermGroup $termGroup -Recursive -ErrorAction Ignore
    if($termCat -ne $null)
    {
        # Got through each page
        foreach($item in $items)
        {
            #if($item.FileSystemObjectType -eq "Folder") { continue } 

            $item.Context.Load($item)
            $item.Context.ExecuteQuery()
            Write-host "  Page ID:"$item.Id "----- Title:"$item["Title"] "----- FileLeafRef:"$item["FileLeafRef"]

            # Get existing values in Categories field
            $catsExisting = $item["ShareCategories"]
            $newCats = @();
            foreach($catExisting in $catsExisting)
            {
                $newCats += "-1;#" + $catExisting.Label + "|" + $catExisting.TermGuid
            }
            # Add term to Categories field
            $newCats += "-1;#" + $termCat.Name + "|" + $termCat.Id.Guid
            
            # Parse values for tax field
            $newCatsValue = $newCats -join ";#"
            $taxFieldValues = New-Object Microsoft.SharePoint.Client.Taxonomy.TaxonomyFieldValueCollection($ctx, $newCatsValue, $taxField)
            $taxField.SetFieldValueByValueCollection($item, $taxFieldValues)

            $item.SystemUpdate()

            $ctx.Load($item)
            $ctx.ExecuteQuery()
        }
    }
    else { Write-host " -- ERROR-1 : term in Categories not found!" }
}

Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "