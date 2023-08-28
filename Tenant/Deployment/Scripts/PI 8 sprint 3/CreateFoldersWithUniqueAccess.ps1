Param(
    [Parameter(Mandatory=$true)][string]$AppId,
    [Parameter(Mandatory=$true)][string]$AppSecreat,
    [Parameter(Mandatory=$true)][string]$CSVPath,
    [Parameter(Mandatory=$true)][string]$SiteUrl,
    [Parameter(Mandatory=$true)][string]$Filepath,
    [Parameter(Mandatory=$true)][string]$GroupOwners,
    [Parameter(Mandatory=$true)][string]$TenantUrl

)

$replaceTable = @{"ß"="ss";"à"="a";"á"="a";"â"="a";"ã"="a";"ä"="a";"å"="a";"æ"="ae";"ç"="c";"è"="e";"é"="e";"ê"="e";"ë"="e";"ì"="i";"í"="i";"î"="i";"ï"="i";"ð"="d";"ñ"="n";"ò"="o";"ó"="o";"ô"="o";"õ"="o";"ö"="o";"ø"="o";"ù"="u";"ú"="u";"û"="u";"ü"="u";"ý"="y";"þ"="p";"ÿ"="y"}

$fileCsv = Import-Csv -Path $CSVPath -Delimiter "," -Encoding Unicode
Connect-PnPOnline -Url $SiteUrl -AppId $AppId -AppSecret $AppSecreat

foreach($row in $fileCsv) {
      foreach($key in $replaceTable.Keys)
      {
        $manager1 = $row.Manager
        $manager1 = $manager1.toLower()
        $manager = $manager1 -replace $key,$replaceTable.$key 
      }

    $actualfolderName = $manager + "_" + $row.Manager_EmailID
    echo $actualfolderName
    Add-PnPFolder -Name $actualfolderName -Folder "Shared Documents"
    $folderName = 'Shared Documents\' + $actualfolderName;
    echo $folderName
    $hrPartnerEmailIds = $row.HR_PartnerEmailID.split(";")
    
    Set-PnPFolderPermission -List 'Shared Documents' -Identity $folderName  -User $row.Manager_EmailID -AddRole 'Contribute' -ClearExisting
    if($hrPartnerEmailIds.length -eq 1)
    {
        Set-PnPFolderPermission -List 'Shared Documents' -Identity $folderName  -User $row.HR_PartnerEmailID -AddRole 'Contribute'
    }else {
        foreach($hrPartner in $hrPartnerEmailIds){
            Set-PnPFolderPermission -List 'Shared Documents' -Identity $folderName  -User $hrPartner -AddRole 'Contribute'
        }
    }
    
    Set-PnPFolderPermission -List 'Shared Documents' -Identity $folderName  -Group $GroupOwners -AddRole 'Full Control'
    Add-PnPFile -Path $Filepath -Folder $folderName
    # Get Folder Url and Create New Csv
    $folderUrl = Get-PnPFolder -Url $folderName -Includes ServerRelativePath
    $fullFolderUrl = $TenantUrl + $folderUrl.ServerRelativePath.DecodedUrl
    $rowFull = $row.HR_Partner + "," + $row.Manager + "," + $row.Manager_ID + "," + $row.Manager_EmailID + "," + $row.HR_PartnerEmailID + "," + $fullFolderUrl
    $rowFull | Out-File -FilePath "c:\temp\Managers.txt" -Append
}
DisConnect-PnPOnline