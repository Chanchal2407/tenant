<# 
.SYNOPSIS
     Script to export files from any SharePoint web folder
.DESCRIPTION
	 Downloads files from SharePoint to local disk. Include folder structure (sub folders)
	 Parameter -Path is destination folder to store the files. It can be relative (e.g. 'Files') or absolute (e.g. "C:\Files")
.NOTES
     Author: Mihails Sotnicoks @ AlfaLaval
	 PNP Powershell is required. Download from https://github.com/SharePoint/PnP-PowerShell/releases
.EXAMPLE
	 .\ExportFiles.ps1 -SiteUrl https://kakandos.sharepoint.com/sites/ShareEv -SiteFolder "SiteAssets" -Path "Files"
#>
param (
    [string]$SiteUrl = $(throw "-SiteUrl Parameter is required."),
	[string]$SiteFolder = "SiteAssets/SitePages",
	[string]$Login = "",
	[string]$Password = "",
	[string]$Path = "SitePagesAssets"	
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

function DownloadFiles($FolderUrl)
{
	$DestFolderPath = ($Path+$FolderUrl.Remove(0,$SiteFolder.Length)).Trim('/');
	
	#Create Directory	
	if (!(Test-Path -path $DestFolderPath)) {
        $DestFolder = New-Item $DestFolderPath -type directory 
    }	

	$FilesInFolder= Get-PnPFolderItem  -FolderSiteRelativeUrl $FolderUrl -ItemType File
	foreach ($file in $FilesInFolder)
	{	 
		Get-PnPFile -AsFile -Url "$FolderUrl/$($file.Name)" -Path $DestFolderPath -Force
	}
	
	$FoldersInFolder= Get-PnPFolderItem  -FolderSiteRelativeUrl $FolderUrl -ItemType Folder
	foreach ($folder in $FoldersInFolder)
	{	 
		# Process folders recursively
		DownloadFiles -FolderUrl "$FolderUrl/$($folder.Name)"		
	}
}

DownloadFiles -FolderUrl $SiteFolder
