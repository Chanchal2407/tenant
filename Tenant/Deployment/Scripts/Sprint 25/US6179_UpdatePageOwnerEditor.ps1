#
#    Alfa Laval
#    User Story 6179 : Organization pages, IT Support and Learning portal - Page footer implementation
#    Task 6193 : IT Support and Learning portal. Update Owners and Editors from the file
#

# ------------ input variables ------------
# URL and creds for connection
$url = "https://diezvai.sharepoint.com/"
$user = "kristaps@diezvai.onmicrosoft.com"
$pssw = 'MansTenants00' | ConvertTo-SecureString -asPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user,$pssw)
Connect-PnPOnline -Url $url –Credentials $cred

# Additional params
$outputpath = "C:\KV\PowerShell\AL\T6193_updatePageOwnersEditors"
$excelPath = "C:\KV\PowerShell\AL\T6193_updatePageOwnersEditors\DEV.xlsx"
#$excelPath = "C:\KV\PowerShell\AL\T6193_updatePageOwnersEditors\ITSupport.xlsx"
#$excelPath = "C:\KV\PowerShell\AL\T6193_updatePageOwnersEditors\LearningTraining.xlsx"

$pageOwnerField = "ALFA_Org_PageOwners"
$pageEditorField = "ALFA_Org_PageEditors"

# ------------ process data ------------
Write-Host "- - - - - - - Script started - - - - - - -"  -f Yellow

# read excel into array
$allPages = @()
$allErrors = @()
$rowNr = 2

$excel = New-Object -Com Excel.Application
$wb = $excel.Workbooks.Open($excelPath)
$sh = $wb.Sheets.Item(1)
$row = $sh.Rows.Item($rowNr)
while ($row.Columns.Item(1).Text.Length -gt 1) {
    $allPages += New-Object PSObject -Property @{
        SiteUrl = $row.Columns.Item(4).Text;
        PageUrl = $row.Columns.Item(5).Text; 
        PageEditor = $row.Columns.Item(2).Text; 
        PageOwner = $row.Columns.Item(3).Text; 
    }
    $rowNr++
    $row = $sh.Rows.Item($rowNr)
}
$excel.Workbooks.Close()

Write-Host "Exccel records found: $($allPages.Count)"
Write-Host "- - - - - - -"

   
$cnt = 0
foreach ($page in $allPages) {
    # get page file name
    $pageFileName = $page.PageUrl.Substring($page.PageUrl.LastIndexOf("/")+1)
    Write-Host "site: " $page.SiteUrl
    Write-Host "page: " $pageFileName -NoNewline
    
    # connect
    Connect-PnPOnline -Url $page.SiteUrl -ClientId $graphappId -CertificatePath $certificatePath -CertificatePassword $certiPassword -Tenant $AADDomain
    
    # get page
    $oPage = Get-PnPClientSidePage -Identity $pageFileName -ErrorAction SilentlyContinue
    
    # process page
    if ($oPage -ne $null) {
        Write-Host " Found" -ForegroundColor Green
        
        # update owner
        Write-Host "owner:" $page.PageOwner "" -NoNewline
        try {
            Set-PnPListItem -List "Site Pages" -Identity $oPage.PageListItem.Id -SystemUpdate:$true -Values @{$pageOwnerField = $page.PageOwner} | Out-Null
            Write-Host "Updated" -ForegroundColor Green
        } catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
            # add error
            $allErrors += New-Object PSObject -Property @{
                SiteUrl = $page.SiteUrl;
                PageUrl = $page.PageUrl;
                ErrorMsg = $_.Exception.Message;
            }
        }

        # update editor
        Write-Host "editor:" $page.PageEditor "" -NoNewline
        try {
            Set-PnPListItem -List "Site Pages" -Identity $oPage.PageListItem.Id -SystemUpdate:$true -Values @{$pageEditorField = $page.PageEditor} | Out-Null
            Write-Host "Updated" -ForegroundColor Green
        } catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
            # add error
            $allErrors += New-Object PSObject -Property @{
                SiteUrl = $page.SiteUrl;
                PageUrl = $page.PageUrl;
                ErrorMsg = $_.Exception.Message;
            }
        }

    } else {
        # page not exists
        Write-Host " Not found" -ForegroundColor Red
        # add error
        $allErrors += New-Object PSObject -Property @{
            SiteUrl = $page.SiteUrl;
            PageUrl = $page.PageUrl;
            ErrorMsg = "page not found";
        }
    }
    
    # disconnect
    Disconnect-PnPOnline
    
    $cnt++
    Write-Host "- - - - - - -"
}

Write-Host "- - - - - - Script completed - - - - - - -" -f Yellow

# summary
Write-host "Pages processed:" $cnt
Write-host "Errors count:" $allErrors.Count

# log errors
if ($allErrors.Count -gt 0) {
    #$logFileName = $outputpath +"\log_errors_" + $(Get-Date -Format "yyyy-MM-dd_HH-mm-ss") + ".csv"
    $logFileName = $outputpath + "TEST.csv"
    $allErrors | Export-Csv -Path $logFileName -NoTypeInformation
    Write-host "Errors log file:"
}