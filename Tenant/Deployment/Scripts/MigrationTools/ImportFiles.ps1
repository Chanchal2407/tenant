<# .SYNOPSIS
     Imports files to SharePoint from local storage
.DESCRIPTION
	 Uploads files from folder in disk(Path parameter) to specified folder inside of SharePoint web. Include folder structure (sub folders)
	 Parameter -SiteFolder is folder inside of Web. For "SitePages" folder in "Site Assets" library use "SiteAssets/SitePages"
	 Parameter -Path is destination folder to store the files. It can be relative (e.g. 'Files') or absolute (e.g. "C:\Files")
.NOTES
     Author: Mihails Sotnicoks @ AlfaLaval
	 PNP Powershell is required. Download from https://github.com/SharePoint/PnP-PowerShell/releases
.EXAMPLE
	 .\ImportFiles.ps1 -SiteUrl https://kakandos.sharepoint.com/sites/ShareEv -SiteFolder "SiteAssets" -Path "Files"
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


(Get-ChildItem $path -Recurse) | %{
	 if($_.GetType().Name -eq "FileInfo"){
	 		$FileDirectory =$_.DirectoryName.Remove(0,$_.DirectoryName.IndexOf($Path)+$Path.Length+1);
			$DestFolder = ($SiteFolder+ "/" +$FileDirectory).Trim('/');
			$File = Add-PnPFile -Path $_.FullName -Folder $DestFolder -ErrorAction Inquire
	 }
 
 }