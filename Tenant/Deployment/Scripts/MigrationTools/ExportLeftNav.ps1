<# .SYNOPSIS
     Script to export left navigation links  CSV
.DESCRIPTION
	 Extracts data from site left navigation - Quick Launch
	 Export to CSV in UTF8 Encoding.
.NOTES
     Author: Mihails Sotnicoks @ AlfaLaval
	 PNP Powershell is required. Download from https://github.com/SharePoint/PnP-PowerShell/releases
.EXAMPLE
	 .\ExportLeftNav.ps1 -SiteUrl https://kakandos.sharepoint.com/sites/ShareEv -FileName "LeftNav.csv"
#>
param (
    [string]$SiteUrl = "https://kakandos.sharepoint.com/sites/ShareEv", #$(throw "-SiteUrl Parameter is required."),
	[string]$FileName = "LeftNav.csv",
	[string]$Login = "",
	[string]$Password = ""
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

$global:Output = @();
$WebUrl = (Get-PnPWeb).ServerRelativeUrl;

function AddToArray($obj,$parentId=$null)
{
	$global:Output +=[PSCustomObject]@{  
	  Id = $obj.Id	
	  Title = $obj.Title
	  Url = $obj.Url
	  IsExternal = $obj.IsExternal
	  ParentId = $parentId
	  WebUrl = $WebUrl
	}
}

Get-PnPNavigationNode -Location QuickLaunch  | %{
	
	AddToArray -obj $_;
	$_.Context.Load($_.Children)
	$_.Context.ExecuteQuery()
	
	Foreach ($c1 in $_.Children)
	{
		AddToArray -obj $c1 -parentId $_.Id
		# 3rd level
		$_.Context.Load($c1.Children)
		$_.Context.ExecuteQuery()
		Foreach ($c2 in $c1.Children) { AddToArray -obj $c2 -parentId $c1.Id }	
	}	
}

$global:Output | Export-Csv -Path $FileName -NoTypeInformation -Encoding UTF8


