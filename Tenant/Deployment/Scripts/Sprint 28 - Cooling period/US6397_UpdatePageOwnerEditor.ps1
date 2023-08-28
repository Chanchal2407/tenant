
# Reads Csv file and updates PageOwner and Editor column in Site Pages library

$url = "https://alfalavalonline.sharepoint.com/sites/share/aboutme/sweden/"
$user = "gurudatt.bhat@alfalaval.com"
$pssw = '****' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url -Credentials $cred

$csvPath = "C:\temp\.xlsx"

$pageOwnerField = "ALFA_PageOwners"
$pageEditorField = "ALFA_PageEditors"

# Encoding UTF7 is used, so Url's with special characters are read correctly.
$pageDetails = Import-Csv -Path "C:\temp\About Me Sweden_pages_191007.csv" -Delimiter ";" -encoding UTF7
Connect-PnPOnline -Url $url -Credentials $cred
foreach( $page in $pageDetails ) {    
         echo $page.PageUrl
         # get page
         $pageFileName = $page.PageUrl.Substring($page.PageUrl.LastIndexOf("/")+1)
         $oPage = Get-PnPClientSidePage -Identity $pageFileName -ErrorAction SilentlyContinue
         if($null -ne $oPage) {
            Set-PnPListItem -List "Site Pages" -Identity $oPage.PageListItem.Id -SystemUpdate:$true -Values @{$pageOwnerField = $page.InformationOwner;$pageEditorField = $page.Editor} | Out-Null
            echo "Page Updated"
         }
}