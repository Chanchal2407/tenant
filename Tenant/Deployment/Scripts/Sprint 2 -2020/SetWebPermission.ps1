#PRE-REQ : PNP POWERSHELL INSTALLED IN LOCAL MACHINE
[CmdletBinding()]
param (
        [Parameter(Mandatory=$true)]
        [string]$WebUrl,
        [Parameter(Mandatory=$true)]
        [string]$PermissionLevelToSet
)
$reVal = Read-Host "Pre-requisite to Chaning Permission Roles is, Site MUST have unique permission.Is the Web Url passed has Unique permission to it ? (yes/No)"
if($reVal -eq "yes") {
Connect-PnPOnline -Url $WebUrl
$memberGroup = Get-PnPGroup -AssociatedMemberGroup
if($null -ne $memberGroup) {
        Set-PnPGroupPermissions -Identity $memberGroup.Id -AddRole @($PermissionLevelToSet)
        Set-PnPGroupPermissions -Identity $memberGroup.Id -RemoveRole @('Edit')
  }
} else {
     Write-Host "Please set Unique permission on the Site before changing permission Roles."   
}

Disconnect-PnPOnline