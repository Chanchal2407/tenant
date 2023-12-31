<# .SYNOPSIS
     Script to import modern pages from CSV file
.DESCRIPTION
	 Creates modern pages in given Web. Uses CSV file as data source.
	 CSV must be created by Export script.
	 By passing 'Overwrite' parameter script will re-create items if they already exist with same name.
.NOTES
     Author: Mihails Sotnicoks @ AlfaLaval
	 PNP Powershell is required. Download from https://github.com/SharePoint/PnP-PowerShell/releases
.EXAMPLE
	 .\ImportModernPages.ps1 -SiteUrl https://kakandos.sharepoint.com/sites/ShareEv -FileName "Pages.csv" -Overwrite:$false
#>
param (
    [string]$SiteUrl = $(throw "-SiteUrl Parameter is required."),
	[string]$FileName = "SitePages.csv",
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

Connect-PnPOnline -Url $SiteUrl -Credentials $O365Credential -ErrorAction Stop
$ImportData = Import-Csv $FileName -Encoding UTF8 -ErrorAction Stop

$WebUrl = (Get-PnPWeb).ServerRelativeUrl;
function ReplaceLink($Content, $OldUrl)
{
	if ($ReplaceLinks) {return $Content.Replace("$OldUrl/","$WebUrl/");}
	else {return $Content }
}


foreach($file in $ImportData)
{	
	#Check if pages already exist
	$Page = Get-PnPClientSidePage -Identity $file.FileName -ErrorAction SilentlyContinue	
	if (($Page -ne $null) -and !$Overwrite) {continue;}
		
	if ($Page -eq $null)
	{
		#Create folder if doesn't exist
		if ($file.FileName.Contains('/')){
			$FolderName=$file.FileName.Substring(0, $file.FileName.LastIndexOf('/'));	
			if ((Get-PnPFolder -Url "SitePages/$Foldername" -ErrorAction SilentlyContinue) -eq $null )
			{
				Add-PnPFolder -Folder "SitePages" -Name $Foldername
			}				
		}
		$Page = Add-PnPClientSidePage -Name $file.FileName -ErrorAction Inquire
	}
	
	if ([string]::IsNullOrEmpty($file.PageLayoutType))	{ $file.PageLayoutType="Article" }
	Set-PnPListItem -List "SitePages" -Identity $Page.PageListItem.Id -SystemUpdate:$true -Values @{"CanvasContent1"= ReplaceLink -Content $file.CanvasContent1 -OldUrl $file.WebUrl;  "LayoutWebpartsContent"= ReplaceLink -Content $file.LayoutWebpartsContent -OldUrl $file.WebUrl;  "PageLayoutType"=$file.PageLayoutType;"BannerImageUrl"=$file.BannerImageUrl; } 	
	$Page = Set-PnPClientSidePage -Identity $file.FileName -Title $file.Title -Publish
}
