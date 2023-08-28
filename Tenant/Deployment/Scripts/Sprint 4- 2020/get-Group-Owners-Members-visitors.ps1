[CmdletBinding()]
Param(
)

# Add below variables value during execution. Removing values before checkin to VSTS.
$tenant = ""
$appId = ""
$appSecret = ""
$luveRelatedSites = Import-Csv -Path "LUVERelatedSites.csv" -Delimiter ","
#TODO: Dont store  Certificate and key in script. Look into options to read it from better secured place
$PEMCertificate = "******";  
$PEMPrivateKey = "******";


foreach($partnerSite in $luveRelatedSites){
    
    $siteOwnersEmail = ""
    $siteOwnersName = ""
    $siteMembersEmail = ""
    $siteMembersName = ""
    $visitorsEmail = ""
    $visitorsName = ""

    Write-Host "`t"$partnerSite.Url -ForegroundColor Yellow
    Connect-PnPOnline -Url  $partnerSite.Url -ClientId "ad1a97cf-acbc-48c0-a55f-b69d7f4226b2" -PEMCertificate $PEMCertificate -PEMPrivateKey $PEMPrivateKey -Tenant $tenant
    #Identify Site Type GROUP SITE OR NO-O365 GROUP SITE
    $site = Get-PnPSite -Includes GroupId
    If($site.GroupId.ToString() -eq "00000000-0000-0000-0000-000000000000"){
        # Non group site
        # Get Owner group Name
        $OwnersGroup = Get-PnPGroup -AssociatedOwnerGroup
        $owners = Get-PnPGroupMembers -Identity $OwnersGroup.Title
        if($null -ne $owners){
           foreach($owner in $owners){
               Write-Host $owner.Email
               $siteOwnersEmail = $siteOwnersEmail + ";" + $owner.Email
               $siteOwnersName = $siteOwnersName + ";" + $owner.Title
           }
        }
        $siteDetails =  $partnerSite.SiteTitle + "," + $partnerSite.Url + "," +  $siteOwnersEmail + "," + $siteOwnersName
        $siteDetails | Out-File -FilePath ".\PartnersRelativeSites.txt" -Append
    }
    else {
        # Group site
        Write-Host "Group site" -ForegroundColor Green
        Connect-PnPOnline -AppId $appId -AppSecret $appSecret -AADDomain $tenant
        # Get Owners list
        $owners = Get-PnPUnifiedGroupOwners -Identity $site.GroupId.ToString()
        if($null -ne $owners) {
            foreach($owner in $owners){
                Write-Host $owner.UserPrincipalName
                $siteOwnersEmail = $siteOwnersEmail + ";" + $owner.UserPrincipalName
                $siteOwnersName = $siteOwnersName + ";" + $owner.DisplayName
            }
        }
        # Get Members list
        $members = Get-PnPUnifiedGroupMembers -Identity $site.GroupId.ToString()
        if($null -ne $members) {
            foreach($member in $members){
                Write-Host $member.UserPrincipalName
                $siteMembersEmail = $siteMembersEmail + ";" + $member.UserPrincipalName
                $siteMembersName = $siteMembersName + ";" + $member.DisplayName
            }
        }
        # Get Visitors list
        Connect-PnPOnline -Url  $partnerSite.Url -ClientId "ad1a97cf-acbc-48c0-a55f-b69d7f4226b2" -PEMCertificate $PEMCertificate -PEMPrivateKey $PEMPrivateKey -Tenant $tenant
        $visitorsGroup = Get-PnPGroup -AssociatedVisitorGroup
        $visitors = Get-PnPGroupMembers -Identity $visitorsGroup.Title
        if($null -ne $visitors) {
            foreach($visitor in $visitors){
                Write-Host $visitor.Title
                $visitorsEmail = $visitorsEmail + ";" + $visitor.Email
                $visitorsName = $visitorsName + ";" + $visitor.Title
            }
        }

        $siteDetails =   $partnerSite.Url + "," +  $siteOwnersEmail + "," + $siteOwnersName + "," +  $siteMembersEmail + "," + $siteMembersName + "," +  $visitorsEmail + "," + $visitorsName
        $siteDetails | Out-File -FilePath ".\LUVERelatedSites.txt" -Append
    }   
}
