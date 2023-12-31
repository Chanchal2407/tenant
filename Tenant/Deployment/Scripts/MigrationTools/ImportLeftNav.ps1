
<# .SYNOPSIS
     Script to import left navigation from CSV file
.DESCRIPTION
	 Creates left navigation node (Quick Launch) in given Web. Uses CSV file as data source.
	 CSV must be created by Export script.
	 By passing 'Overwrite' parameter will clear all left navigation
.NOTES
     Author: Mihails Sotnicoks @ AlfaLaval
	 PNP Powershell is required. Download from https://github.com/SharePoint/PnP-PowerShell/releases
.EXAMPLE
	 .\ImportLeftNav.ps1 -SiteUrl https://kakandos.sharepoint.com/sites/ShareEv -FileName "LeftNav.csv" -Overwrite:$false
#>
param (
    [string]$SiteUrl = $(throw "-SiteUrl Parameter is required."),
	[string]$FileName = "LeftNav.csv",
	[string]$Login = "",
	[string]$Password = "",
	[switch]$ReplaceLinks =$true,
	[switch]$Overwrite = $true
	
)

if ([string]::IsNullOrEmpty($Login))
{
	$O365Credential = Get-Credential
}
else
{
	$securePassword = ConvertTo-SecureString $Password –AsPlainText –force
	$O365Credential = New-Object System.Management.Automation.PsCredential($Login, $securePassword)
}

Connect-PnPOnline -Url $SiteUrl -Credentials $O365Credential


$ImportData = Import-Csv $FileName -Encoding UTF8 -ErrorAction Stop

$WebUrl = (Get-PnPWeb).ServerRelativeUrl;
function ReplaceLink($Content, $OldUrl)
{
	if ($ReplaceLinks) {return $Content.Replace("$OldUrl/","$WebUrl/");}
	else {return $Content }
}

if ($Overwrite)
{	#Clear all left nav
	Get-PnPNavigationNode -Location QuickLaunch | Remove-PnPNavigationNode -Force 
}

#Import childs recursively
function AddChildNodes($SiteNodeId,$ParentId)
{
	$ImportData | Where-Object -FilterScript {$_.ParentId -eq $ParentId} | % {	
		$Node = Add-PnPNavigationNode -Location QuickLaunch -Title $_.Title -Url (ReplaceLink -Content $_.Url -OldUrl $_.WebUrl)  -External:([Bool]::Parse($_.IsExternal)) -Parent $SiteNodeId
		AddChildNodes -SiteNodeId $Node.Id -ParentId $_.Id
	}
}

#Import top nodes
$ImportData | Where-Object -FilterScript {$_.ParentId -eq ""} | % {
	$Node = Add-PnPNavigationNode -Location QuickLaunch -Title $_.Title -Url (ReplaceLink -Content $_.Url -OldUrl $_.WebUrl) -External:([Bool]::Parse($_.IsExternal))
	AddChildNodes -SiteNodeId $Node.Id -ParentId $_.Id
}
