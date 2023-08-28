#
#    Alfa Laval
#    Task 5766 : Write powershell script to be able to add -qa and -uat web parts
#


# ------ input variables ------
# URL for site and credentials for connection
$url = "https://contoso.sharepoint.com/sites/colaborationSite/"
$user = "admin@contoso.onmicrosoft.com"
$pssw = 'password' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

# title or name of page (located in library "Site Pages" in current site)
$page = "home.aspx"

# webpart and enviroment - available values:
#    Tool Cards-qa
#    Tool Cards-uat
#    About Site-qa
#    About Site-uat
#    Portable News Web Part-qa
#    Portable News Web Part-uat
#    Local Sites Directory-qa
#    Local Sites Directory-uat
#    Tool Sites Directory-qa
#    Tool Sites Directory-uat
$webpart = "Tool Cards-qa"


# ------ insert webpart to main page ------
Add-PnPClientSideWebPart -Page $page -Component $webpart -Section 1 -Column 1


# ------ bonus : get all available components (using Name column in $webpart) ------
#Get-PnPAvailableClientSideComponents -Page $page


Disconnect-PnPOnline

Write-Host "End" -f Green -b DarkGreen
Write-host " "
Write-host " "