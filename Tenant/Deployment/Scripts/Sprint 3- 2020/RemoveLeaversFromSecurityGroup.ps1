#PRE-REQ : PNP POWERSHELL INSTALLED IN LOCAL MACHINE
[CmdletBinding()]
param (
        [Parameter(Mandatory=$true)]
        [string]$WebUrl,
        [Parameter(Mandatory=$true)]
        [string]$SecurityGroupName
)

Connect-PnPOnline -Url $WebUrl
Get-PnPGroupMembers -Identity $SecurityGroupName | %{
    if($_.Email -like "Leaver_*") {
        Write-Host $_.Email
        Remove-PnPUserFromGroup -LoginName $_.Email -Identity $SecurityGroupName
        Write-Host "Removed ${$_.Email} successfully" -ForegroundColor Green
    }
}