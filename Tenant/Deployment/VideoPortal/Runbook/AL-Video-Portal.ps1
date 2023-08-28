$clientID = $null
$certificatePassword = $null
$bas64Encoded = $null

# To get automation certificate 
$appCert = Get-AutomationCertificate –Name "AzureAppCertificate"

if ($null -eq $certificatePassword) {
    # To retrive the Certificate password
    $certificatePassword = Get-AutomationPSCredential –Name 'AzureAppCertPassword'
}
 
if ($null -eq $bas64Encoded) {
    # Export the certificate and convert into base 64 string
    $bas64Encoded = [System.Convert]::ToBase64String($appCert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $certificatePassword.Password))
}

if ($null -eq $clientId) {
    # To get Client Id 
    $clientId = Get-AutomationVariable –Name 'AppClientId'
}

# VARIABLES - Get all required automation variables
[String]$env = Get-AutomationVariable -Name 'Environment'
[String]$tenantAdminUrl = Get-AutomationVariable -Name 'TenantAdminUrl'
[String]$tenantUrl = Get-AutomationVariable -Name 'TenantUrl'
[String]$portalSiteUrl = Get-AutomationVariable -Name 'PortalSiteUrl'
[String]$tenant = Get-AutomationVariable -Name 'Tenant'
[String]$supportUsers = Get-AutomationVariable -Name 'SupportUsers'
[String]$requestListName = Get-AutomationVariable -Name 'RequestListName'
[String]$everyoneExceptExternalUsers = Get-AutomationVariable -Name 'EveryoneExceptExternalUsers'
[String]$communicationTemplate = Get-AutomationVariable -Name 'CommunicationTemplate'

[String]$videoPortalPnPTemplateName = Get-AutomationVariable -Name 'VideoPortal-PnPTemplateName'
[String]$videoPortalSiteDesignId = Get-AutomationVariable -Name 'VideoPortal-SiteDesignId'
[String]$videoPortalSiteTypePrefix = Get-AutomationVariable -Name 'VideoPortal-SiteTypePrefix'


# Connection function
function Connect-AzureADAppOnly([String]$ConnectionUrl) {
    Connect-PnPOnline -ClientId $clientId -CertificateBase64Encoded $bas64Encoded `
                    -CertificatePassword $certificatePassword.Password `
                    -Url $ConnectionUrl -Tenant $tenant
}

Try {
    if($env.ToUpper() -ne "PROD") {
        $env = $env.ToUpper()
    }
    else {
        $env = [String]::Empty
    }

    $camlQuery = "<View><Query><Where><And><Eq><FieldRef Name='SiteType' /><Value Type='Choice'>Organization Video Channel</Value></Eq><Eq><FieldRef Name='SiteStatus' /><Value Type='Choice'>Approved</Value></Eq></And></Where></Query></View>"

    Connect-AzureADAppOnly -ConnectionUrl $portalSiteUrl 

    $ListItems = Get-PnPListItem -List $requestListName -Query $camlQuery   
    
    foreach ($ListItem in $ListItems) {
    
        $RequestSiteId = $ListItem.FieldValues["ID"]
        $SiteTitle = $ListItem.FieldValues["Title"].ToString()
        $ShortDesc = $ListItem.FieldValues["ShortDescription"].ToString()
         
        $SiteOwners = New-Object 'Collections.Generic.List[string]'
        $SiteEditors = New-Object 'Collections.Generic.List[string]'

        foreach ($userOwner in $ListItem["SiteOwner"])
        {
            $siteOwners.Add($userOwner.Email)
        }
        foreach ($userEditor in $ListItem["SiteEditor"])
        {
            $SiteEditors.Add($userEditor.Email)
        }

        $NewPortalSiteUrl = $portalSiteUrl.Substring(0, $portalSiteUrl.LastIndexOf("/")) + "/" + $videoPortalSiteTypePrefix + $env  + "-" + ($SiteTitle -replace "[^a-zA-Z0-9_-]+").ToLower()
        $DesignTitle = ($env + " AlfaLaval design -  Video Portal site").TrimStart()

        [String]$actualSiteUrl = [string]::Empty
        [String]$CreatedPortalSiteUrl = [string]::Empty
        
        Try {        
            Connect-AzureADAppOnly -ConnectionUrl $tenantAdminUrl
            [int]$attemptNumber = 0
            [bool]$fileAlreadyExist = $true
            $attemptStr

            while($fileAlreadyExist -and $attemptNumber -lt 30) {
                     
                if($attemptNumber -eq 0) {
                    $attemptStr = [string]::Empty
                } else {
                    $attemptStr = $attemptNumber.ToString()
                }
        
                $actualSiteUrl = $NewPortalSiteUrl+$attemptStr

                $CheckIfSiteExists = Get-PnPTenantSite | Where {$_.Url -eq $actualSiteUrl}

                if($CheckIfSiteExists) {
                    $attemptNumber++
                } else {
                    $fileAlreadyExist = $false
                }
            }

            if($fileAlreadyExist -eq $true) {
                echo "Can't generate valid URL for the site! Number of attempts exceeded!"
                $actualSiteUrl = [String]::Empty
            } 
            else {
                echo "Organization video portal site creation started... $actualSiteUrl"         
                New-PnPTenantSite -Url $actualSiteUrl -Title $SiteTitle -Owner $SiteOwners[0] -Template $communicationTemplate -TimeZone 13 -Lcid 1033
                echo "DONE" 
            }
        }
        Catch {
            Write-Error "Exception occured in CreateCommunicationSite(): $_"
        }        
        Start-Sleep -Seconds 30
        $CreatedPortalSiteUrl = $actualSiteUrl        

        Try {
            Connect-AzureADAppOnly -ConnectionUrl $portalSiteUrl

            $ListItems1 = Get-PnPListItem -List "Site Assets"
            [String]$PnPPath = [string]::Empty

            foreach($listItem3 in $ListItems1) {            
                if($listItem3["Title"] -eq $videoPortalPnPTemplateName) {
                    $PnPPath = $tenantUrl + $listItem3["FileRef"]
                    echo "Video portal template path: $PnPPath"
                }
            }
        
            Disconnect-PnPOnline

            Connect-AzureADAppOnly -ConnectionUrl $CreatedPortalSiteUrl.TrimStart()
            
            if(![string]::IsNullOrEmpty($PnPPath)){                           
                $ctx = Get-PnPContext
                if ($ctx.Url.TrimStart() -eq $CreatedPortalSiteUrl.TrimStart()) {
                    echo "Applying site template started..."
                    Invoke-PnPSiteTemplate -Path $PnPPath
                    Start-Sleep -Seconds 30
                    echo "DONE"
                }
            }        
        } 
        Catch {
            Write-Error "Exception occured in ApplySiteTemplate(): $_"
        }

        Try {
            Connect-AzureADAppOnly -ConnectionUrl $tenantAdminUrl.TrimStart()
            echo "Applying site desing started..." 
            Invoke-PnPSiteDesign -Identity $videoPortalSiteDesignId -WebUrl $CreatedPortalSiteUrl.TrimStart()
            echo "DONE" 
        } 
        Catch {
            Write-Error "Exception occured in ApplySiteDesign(): $_"
        }

        Try {
            Connect-AzureADAppOnly -ConnectionUrl $CreatedPortalSiteUrl.TrimStart()
            Add-PnPSiteCollectionAdmin -Owners $supportUsers
            echo "Admins added to site... DONE" 
        } 
        Catch {
            Write-Error "Exception occured in AddUsersToSiteAdmins(): $_"
        }

        Try {
            Connect-AzureADAppOnly -ConnectionUrl $CreatedPortalSiteUrl.TrimStart()
            $Web = Get-PnPWeb
            $OwnerGroup = Get-PnPGroup -AssociatedOwnerGroup
            $MemberGroup = Get-PnPGroup -AssociatedMemberGroup

            ForEach($owner in $SiteOwners) {
                Add-PnPGroupMember -LoginName $owner -Identity $OwnerGroup
                echo "Users added to owner group... DONE"
            }
            ForEach($editor in $SiteEditors) {
                Add-PnPGroupMember -LoginName $editor -Identity $MemberGroup
                echo "Users added to member group... DONE"
            }
        } 
        Catch {
            Write-Error "Exception occured in AddUsersToGroup(): $_"
        }
        
        Try {
            Connect-AzureADAppOnly -ConnectionUrl $CreatedPortalSiteUrl.TrimStart()
            $Web1 = Get-PnPWeb
            $VisitorGroup = Get-PnPGroup -AssociatedVisitorGroup
            Add-PnPGroupMember -LoginName $everyoneExceptExternalUsers -Identity $VisitorGroup
            echo "Everyone except external users added to visitor group... DONE" 
        } 
        Catch {
            Write-Error "Exception occured in AddEveryoneToVisitorGroup(): $_"
        }
       
        Try {
            Connect-AzureADAppOnly -ConnectionUrl $CreatedPortalSiteUrl.TrimStart()
            Set-PnPFooter -Enabled:$false
            echo "Footer disabled... DONE" 
        } 
        Catch {
            Write-Error "Exception occured in DisableSiteFooter(): $_"
        }
        
        Try {
            Connect-AzureADAppOnly -ConnectionUrl $CreatedPortalSiteUrl.TrimStart()
        
            $Owner1 = Get-PnPUser | Where-Object Email -eq $SiteOwners[0]
            $Editor1 = Get-PnPUser | Where-Object Email -eq $SiteEditors[0]

            $ListItem1 = Get-PnPListItem -List "Site Pages" -Id 1
            $ALFA_PageOwners =  Set-PnPListItem -List "Site Pages" -Identity $ListItem1.Id -Values @{"ALFA_PageOwners" =$Owner1.Email.ToString(),$Owner1.Id.ToString()}
            $ALFA_PageEditors =  Set-PnPListItem -List "Site Pages" -Identity $ListItem1.Id -Values @{"ALFA_PageEditors"= $Editor1.Email.ToString(),$Editor1.Id.ToString()}
            $ListItem1.File.Publish("Published")
            Invoke-PnPQuery
            echo "Owners added Editors added to home page... DONE" 
        } 
        Catch {
            Write-Error "Exception occured in SetStartPageOwnerEditor(): $_"
        }
        
        
        Try {
            Connect-AzureADAppOnly -ConnectionUrl $portalSiteUrl.TrimStart()
        
            $updateSiteUrl = $CreatedPortalSiteUrl + ", "  + $SiteTitle
            $ListItem2 = Get-PnPListItem -List $requestListName -Id $RequestSiteId
            $SiteURLSiteStatus = Set-PnPListItem -List $requestListName -Identity $ListItem2.Id -Values @{"SiteURL" = $updateSiteUrl; "SiteStatus" = "Available"}
            echo "Site url and Site status updated... DONE"
        } 
        Catch {
            Write-Error "Exception occured in UpdateSiteUrlStatus(): $_"
        }
    }

    Disconnect-PnPOnline
}
Catch {
    Write-Error "Exception occured in Main(): $_"
}