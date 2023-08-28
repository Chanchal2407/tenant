

Param(
     [Parameter(Mandatory=$true,ValueFromPipeline=$true)]$url,
     [Parameter(Mandatory=$true,ValueFromPipeline=$true)]$csvPath,
     [Parameter(Mandatory=$true,ValueFromPipeline=$true)]$libraryName = "Documents",
     [Parameter(Mandatory=$true,ValueFromPipeline=$true)]$addToSiteVisitor = $false
)

echo "=============  Pre-Requisites : Use PnP.Powershell  ============="
$csvVal = Import-Csv -Path $csvPath -Delimiter ','
if($null -ne $csvVal) {
    # Connect to SharePoint site
    Connect-PnPOnline -Url $url -Credentials (Get-Credential)
    
      #Check if $addToSiteVisitor is true or false. If false, continue to next step. If true, add to site visitor group
        if($addToSiteVisitor){
            # Get Associated Visitor group
            $web = Get-PnPWeb -Includes AssociatedVisitorGroup
            $csvVal | %{
                try{
                    echo "User email" $_.Login
                    # Add users to visitors group
                    Add-PnPUserToGroup -LoginName $_.Login -Identity $web.AssociatedVisitorGroup.Id
                    echo "Added $($_.Login) to visitors successfully"
               }
               catch{
                 echo "An error occurred: $($PSItem.ToString())"
                 $_.Exception.Message | Out-File -FilePath "c:\temp\AddingVisitorsError.txt" -Append
                 $($PSItem.ToString()) | Out-File -FilePath "c:\temp\AddingVisitorsError.txt" -Append
               }
            }
        }

    $csvVal | %{
        try {
        echo "Adding $($_.Login) to $($_.CompanyName) folder"
        Set-PnPFolderPermission -List $libraryName -Identity "Shared $($libraryName)\Master Partners folders\$($_.CompanyName)" -User $_.Login -AddRole 'Contribute' -SystemUpdate
        echo "Adding $($_.ALLogin) to $($_.CompanyName) folder"
        Set-PnPFolderPermission -List $libraryName -Identity "Shared $($libraryName)\Master Partners folders\$($_.CompanyName)" -User $_.ALLogin -AddRole 'Contribute' -SystemUpdate
        echo "Removing $($web.AssociatedVisitorGroup.LoginName) from Shared  $($libraryName)\Master Partners folders\$($_.CompanyName)"
        Set-PnPFolderPermission -List $libraryName -Identity "Shared $($libraryName)\Master Partners folders\$($_.CompanyName)" -Group $web.AssociatedVisitorGroup.LoginName -RemoveRole 'Read' -SystemUpdate
      }
      catch{
        echo "An error occurred: $($PSItem.ToString())"
        $_.Exception.Message | Out-File -FilePath "c:\temp\FolderPermissionError.txt" -Append
        $($PSItem.ToString()) | Out-File -FilePath "c:\temp\FolderPermissionError.txt" -Append
      }
    }
}