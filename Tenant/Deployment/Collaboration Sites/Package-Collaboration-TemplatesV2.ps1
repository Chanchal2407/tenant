# Pre Req: Run this script on Windows Powershell
# Pre Req: Load March 2018 or above PnP powershell module before running the script
# TODO : Load Office PnP module
$validVal = $true
Write-Host "Environment - (Production, UAT,Dev)"
$environment = Read-Host "Type Environment name to create a package"
Write-Host "Templates Available - (CollaborationSite, ProjectSite)"
$templateName = Read-Host " Enter Template name to create .pnp package"
try{
     if ($environment -ne "" -and $templateName -ne "") {
        # Get the file in combination of $templateName-$environment, copy file and rename it, create PnP folder
        Copy-Item -Path ".\Templates\$templateName\$templateName-$environment.xml" -Destination ".\Templates\$templateName\$templateName.xml"
        #Convert-PnPFolderToProvisioningTemplate -Out ".\Templates\$templateName.pnp" -Folder ".\Templates\$templateName"
        Convert-PnPFolderToSiteTemplate -Out ".\Templates\$templateName.pnp" -Folder ".\Templates\$templateName"
        Remove-Item -Path ".\Templates\$templateName\$templateName.xml"
        Write-Host "$templateName.pnp created successfully"
     }
   }
catch {
    Write-Host $_.Exception.Message
    $validVal = $false
    if(!$validVal){
        Write-Host "Invalid environment or template name"
    }
}

