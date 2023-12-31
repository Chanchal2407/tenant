<# .SYNOPSIS
     Script to export modern pages data to CSV
.DESCRIPTION
	 Extracts data from every Modern page in given SharePoint Web - File Name, Title, Layout type and content
	 Uses "Site Pages" library. Consideres folder structure.
	 Export to CSV in UTF8 Encoding.
.NOTES
     Author: Mihails Sotnicoks @ AlfaLaval
	 PNP Powershell is required. Download from https://github.com/SharePoint/PnP-PowerShell/releases
.EXAMPLE
	 .\ExportModernPages.ps1 -SiteUrl https://kakandos.sharepoint.com/sites/ShareEv -Login Admin@kakandos.onmicrosoft.com -Password PAROL -FileName "Pages.csv"
#>
param (
    [string]$SiteUrl = "https://kakandos.sharepoint.com/sites/ShareEv", #$(throw "-SiteUrl Parameter is required."),
	[string]$FileName = "SitePages.csv",
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
$outputdata = @();

$allFiles = Get-PnPListItem -List "SitePages"
$WebUrl = (Get-PnPWeb).ServerRelativeUrl;

foreach($file in $allFiles)
{
	if ($file["FileRef"].EndsWith(".aspx")) #Take only pages, not folders
	{	
		$outputdata+=[PSCustomObject]@{    
		  Title = $file["Title"]
		  FileName = $file["FileRef"].Substring($file["FileRef"].IndexOf("SitePages")+10) #Take Library-Relative Url
		  PageLayoutType = $file["PageLayoutType"]
		  CanvasContent1 = $file["CanvasContent1"]
		  LayoutWebpartsContent = $file["LayoutWebpartsContent"]
		  BannerImageUrl = $file["BannerImageUrl"].Url
		  WebUrl = $WebUrl
		}
	}
}
$outputdata | Export-Csv -Path $FileName -NoTypeInformation -Encoding UTF8