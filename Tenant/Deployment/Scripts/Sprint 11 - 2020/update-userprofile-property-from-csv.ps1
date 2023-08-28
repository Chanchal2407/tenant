#####################################################################################
#Written By : Gurudatt Bhat
#Purpose : Based on CSV file, This script updates IsGroupAccount User profile property value

#####################################################################################
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$TenantAdminUrl,
    [Parameter(Mandatory=$true)]
    [string]$CsvPath
)

$nonRealUserAccounts = Import-Csv -Path $CsvPath -Delimiter ","

$connection = Connect-PnPOnline -Url $TenantAdminUrl -SPOManagementShell
[void](Read-Host 'Press Enter to continue')
if($null -ne $nonRealUserAccounts) {
    foreach($account in $nonRealUserAccounts){
        Set-PnPUserProfileProperty -Account $account.UserPrincipalName -Property 'IsGroupAccount' -Value True -Connection $connection
        Write-Output "IsGroupAccount user profile value set as Yes for  account : " + $account.UserPrincipalName
        $account.UserPrincipalName | Out-File "IsGroupAccount_UserProfileUpdate.txt" -Append
    }
}

Disconnect-PnPOnline