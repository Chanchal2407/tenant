cls
# connection params
# --- DEV ---
$adminSiteURL = "https://fordemo-admin.sharepoint.com"
$adminUsername = "dmitrijs@fordemo.onmicrosoft.com"
$adminPassword = '!Enter1!1' | ConvertTo-SecureString -asPlainText -Force
$excelPath = "C:\Users\dmitrijs.maslobojevs\Desktop\PnP\Sprints\sprint20\2-OfficeLocation.xlsx"


# --- PROD/UAT ---
#$adminSiteURL = "https://alfalavalonline-admin.sharepoint.com"
#$adminUsername = "dmitrijs.maslobojevs@alfalaval.com"
#$adminPassword = 'zesTA33ru' | ConvertTo-SecureString -asPlainText -Force
#$excelPath = "C:\Users\dmitrijs.maslobojevs\Desktop\PnP\Sprints\sprint20\OfficeLocation.xlsx"


# ----- BODY -----
Write-Host "- - - - - - - Script started - - - - - - -"  -ForegroundColor Yellow

# read excel into array
$allUsers = @()
$rowNr = 2

$excel = New-Object -Com Excel.Application
$wb = $excel.Workbooks.Open($excelPath)
$sh = $wb.Sheets.Item(1)
$row = $sh.Rows.Item($rowNr)
while ($row.Columns.Item(1).Text.Length -gt 1) {
    $allUsers += New-Object PSObject -Property @{UserEmail = $row.Columns.Item(1).Text; LocationName = $row.Columns.Item(2).Text }
    $rowNr++
    $row = $sh.Rows.Item($rowNr)
}
$excel.Workbooks.Close()

Write-Host "Exccel records found: $($allUsers.Count)"

# Connect
$credential = New-Object System.Management.Automation.PSCredential ($adminUsername,$adminPassword)
Connect-PnPOnline –Url $adminSiteURL –Credentials $credential 
   
$cnt = 0
foreach ($user in $allUsers) {
    Write-Host $user.UserEmail -NoNewline
    Set-PnPUserProfileProperty -Account $user.UserEmail -Property "SPS-Location" -Value $user.LocationName
    Write-Host " OK" -ForegroundColor Green
}

# Disconnect
Disconnect-PnPOnline

Write-Host "- - - - - - Script completed - - - - - - -" -ForegroundColor Yellow
