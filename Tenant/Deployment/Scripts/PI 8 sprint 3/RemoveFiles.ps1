Param(
    [Parameter(Mandatory=$true)][string]$AppId,
    [Parameter(Mandatory=$true)][string]$AppSecreat,
    [Parameter(Mandatory=$true)][string]$SiteUrl

)

Connect-PnPOnline -Url $SiteUrl -AppId $AppId -AppSecret $AppSecreat

$libFolders = Get-PnPFolderItem -FolderSiteRelativeUrl "Shared Documents" -ItemType Folder
$libFolders | %{

    $filePath = "Shared Documents/" + $_.Name + "/ReadMe.txt"
    echo $filePath
    Remove-PnPFile -SiteRelativeUrl $filePath -Force
}

Disconnect-PnPOnline