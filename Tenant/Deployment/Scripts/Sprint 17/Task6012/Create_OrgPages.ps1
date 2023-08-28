####
#    Alfa Laval
#    Task 6012 : Create a Powershell script to process org pages
#    User Story 5994 : Create a Powershell script to iterate through csv file and create Pages, set page properties and create folder in document library
#    - part of code is re-used from script that creates Modern pages (author : Mihails Sotnicoks)
####


# ------------ input variables ------------
# URL for site and credentials for connection
$rootUrl = "https://contoso.sharepoint.com"
$url = $rootUrl + "/sites/organization-page-site/"
$user = "admin@contoso.onmicrosoft.com"
$pssw = 'password' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

# Input file with info about Organization pages (title, owners, editors)
$csvFilePath = "C:\input.csv"
# Download ZIP package (ALFA.code.OrganizationSites.zip) from User Story and provide path to input file "PageTemplates.csv"
$templateFilePath = "C:\PageTemplates.csv"
# Provide path to output file (where input + new Org page parameters will be written)
$output = "C:\output_PageTemplatesWithUrl.txt"


# ------------ process data ------------
Write-host "Site: " $url

# setup the context
$ctx = Get-PnPContext

# get web title
$webTitle = $(Get-PnPWeb -Includes Title | Select Title).Title

# read term GUIDs from CSV
$csv = Get-Content $csvFilePath
Write-host "CSV contains ["$csv.Length"] entries "

# template data
$template = Import-Csv $templateFilePath -Encoding UTF8 -ErrorAction Stop
Write-host "Template data acquired"

function ReplaceLink($Content, $OldUrl)
{
	if ($ReplaceLinks) {return $Content.Replace("$OldUrl/","$WebUrl/");}
	else {return $Content }
}

for ($i = 1; $i -lt $csv.Count; $i++)
{ 
    $valuesRaw = $csv[$i].Split(';')

    # values for new term
    $global:pageTitle = $valuesRaw[0].Trim()
    $infoOwner = $valuesRaw[3].Trim()
    $infoEditor = $valuesRaw[4].Trim()

    Write-Host "Processing [$global:pageTitle] with users [$infoOwner | $infoEditor] "

    try
    {
        $message = ""

        #
        # create page
        #
        $counter = 0
        $global:page = $null
        function CreatePageWithUniqueTitle ()
        {
            $tempPageTitle = $global:pageTitle
            if($counter -gt 0) { $tempPageTitle = $global:pageTitle + $counter.ToString() }

            $tempPage = Get-PnPClientSidePage -Identity $tempPageTitle -ErrorAction SilentlyContinue	
            if ($tempPage -ne $null) 
            {
                $counter++
                CreatePageWithUniqueTitle
            }
            else
            {
                $tempPage = Add-PnPClientSidePage -Name $tempPageTitle
                $global:pageTitle = $tempPageTitle
                $global:page = $tempPage
            }
        }
        CreatePageWithUniqueTitle
        $message += " --Added"

        #
        # apply template
        #
        Set-PnPListItem -List "SitePages" -Identity $global:page.PageListItem.Id -SystemUpdate:$true -Values @{"CanvasContent1"= ReplaceLink -Content $template.CanvasContent1 -OldUrl $template.WebUrl;  "LayoutWebpartsContent"= ReplaceLink -Content $template.LayoutWebpartsContent -OldUrl $template.WebUrl;  "PageLayoutType"=$template.PageLayoutType;"BannerImageUrl"=$template.BannerImageUrl; } | Out-Null

        $pageName = $global:pageTitle -replace ' ','-'
	    $global:page = Set-PnPClientSidePage -Identity $global:pageTitle -Title $pageName -Publish
        $message += " --template"

        #
        # add users [$infoOwner and $infoEditors] to page properties
        # add users [$infoOwner and $infoEditors] to site groups
        #
        if($infoOwner -ne $null -and $infoOwner.Length -ne 0) 
        { 
            $EVOwner = $null
            Set-PnPListItem -List "SitePages" -Identity $global:page.PageListItem.Id -SystemUpdate:$true -Values @{"ALFA_Org_PageOwners"= $infoOwner} -ErrorAction SilentlyContinue -ErrorVariable EVOwner | Out-Null
            $groupName = "$webTitle Owners"
            
            $user = $null
            $user = Get-PnPGroupMembers -Identity $groupName 
            if(($user | Where-Object {$_.Email -eq $infoOwner}) -eq $null) { Add-PnPUserToGroup -LoginName $infoOwner -Identity $groupName -ErrorAction SilentlyContinue -ErrorVariable EVOwner }

            if($EVOwner.Count -eq 0) { $message += " --PermOwner" }
            else { $message += " --Could not find user [$infoOwner]" }
        }
        

        if($infoEditor -ne $null -and $infoEditor.Length -ne 0) 
        { 
            $EVEditor = $null
            Set-PnPListItem -List "SitePages" -Identity $global:page.PageListItem.Id -SystemUpdate:$true -Values @{"ALFA_Org_PageEditors"= $infoEditor} -ErrorAction SilentlyContinue -ErrorVariable EVEditor | Out-Null
            $groupName = "$webTitle Members"
                
            if($EVEditor.Count -eq 0) { $message += " --PermEditor" }
            else { $message += " --Could not find user [$infoEditor]" }
        }
        
        #
        # create folder in "documents" library
        #
        $folderUrl = "/Shared Documents/" + $global:pageTitle
        $folder = Get-PnPFolder -Url $folderUrl -ErrorAction SilentlyContinue
        if($folder -eq $null) 
        { 
            Add-PnPFolder -Name $global:pageTitle -Folder "Shared Documents/"; 
            $message += " --Fold"
        }

        #
        # generate full page URL and write to output file
        #
        $file = $global:page.PageListItem.File
        $ctx.Load($file)
        $ctx.ExecuteQuery()

        $log = $valuesRaw -join ";"
        $log += ";$rootUrl/" + $file.ServerRelativeUrl + ";" + $global:pageTitle + ".aspx;$folderUrl"
        $log | Out-File $output -Append

        Write-host "    OK-2 : page [$global:pageTitle | ID:"$global:page.PageListItem.Id" | "$file.ServerRelativeUrl"] created [ $message ]"

    }
    catch [System.Exception]
    {
        Write-Host "--- ERROR-1 : Exception : " $_.Exception -f Red
    }
}
   
Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "