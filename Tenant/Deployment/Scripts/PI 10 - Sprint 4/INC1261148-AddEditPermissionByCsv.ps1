
$countryObj = Import-csv -Path "C:\temp\CountryFoldersAndResponsibilities.csv" -Delimiter ","
$libUrl = "Country material"

Connect-PnPOnline -Url "https://alfalavalonline.sharepoint.com/sites/Collaboration-ChannelPartnerProgramme" -UseWebLogin

<#$folderColl= Get-PnPFolderItem -FolderSiteRelativeUrl $folderUrl -ItemType Folder
$folderColl | %{

}
#>
$web = Get-PnPWeb -Includes AssociatedMemberGroup
if($null -ne $countryObj) {
    $countryObj | %{
        echo $_.ALSC
        $folderRelativeUrl = $libUrl + "\" +  $_.ALSC
        # Add HFHMgr
        Set-PnPFolderPermission -List "Country material" -Identity $folderRelativeUrl  -User $_.HFHMgr -AddRole "Edit" -SystemUpdate -ErrorAction SilentlyContinue
        # Add FWMgr
        Set-PnPFolderPermission -List "Country material" -Identity $folderRelativeUrl  -User $_.FWMgr -AddRole "Edit" -SystemUpdate -ErrorAction SilentlyContinue
        # Add HFHCentralresp
        Set-PnPFolderPermission -List "Country material" -Identity $folderRelativeUrl  -User $_.HFHCentralresp -AddRole "Edit" -SystemUpdate -ErrorAction SilentlyContinue
        echo "Added $($_.HFHMgr) $($_.FWMgr) $($_.HFHCentralresp) to $($folderRelativeUrl) successfully";
        # Assign members group read permission 
        Set-PnPFolderPermission -List "Country material" -Identity $folderRelativeUrl  -Group $web.AssociatedMemberGroup.LoginName -RemoveRole "Edit" -SystemUpdate -ErrorAction SilentlyContinue
        Set-PnPFolderPermission -List "Country material" -Identity $folderRelativeUrl  -Group $web.AssociatedMemberGroup.LoginName -AddRole "Read" -SystemUpdate -ErrorAction SilentlyContinue

    }
}

Disconnect-PnPOnline