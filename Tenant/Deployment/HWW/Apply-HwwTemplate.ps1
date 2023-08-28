[cmdletbinding()]		
    Param
    (
        [Parameter(Mandatory=$true)]$SiteUrl
    )
 
    Connect-PnPOnline -Url $SiteUrl
    Apply-PnPProvisioningTemplate -Path "Templates\hww.xml"