##########################################################################

# Site provisioning script
# Developer: Gurudatt Bhat ( AlfaLaval )
# Reference/ CREDIT :
# https://developer.microsoft.com/en-us/office/blogs/provisioning-with-pnp-powershell-and-azure-webjobs/
# https://capacreative.co.uk/2021/02/27/azure-automation-to-the-rescue-session-at-scottish-summit-2021/

#############################

# CHANGE HISTORY #
# 15/06/2021   Gurudatt Bhat
# 17/09/2022 Ravi Rachchh (Teams creation, Draft requests, and Sensitivity label code added)
##########################################################################

param(
    [switch]$Force = $false
)
Import-Module MSAL.PS
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
Write-Output $PSScriptRoot
#echo "$PSScriptRoot\Shared.ps1"
# . "$PSScriptRoot\Shared.ps1"

#Region variables

#################
# DURING DEVELOPMENT ONLY - SAMPLE
<#
$clientId = "4cb98b17-75ba-452d-bd8a-7761d1b9998b";
$bas64Encoded = "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"
$certificatePassword = ConvertTo-SecureString -String "1qaz!QAZ" -AsPlainText -Force
$appAdTenant = "techalfademo.onmicrosoft.com"
$siteDirectorySiteUrl = "https://techalfademo.sharepoint.com/sites/collaborationlanding/collaboration"
$siteDirectoryList = '/Lists/Sites'
$templateConfigurationsList = '/Lists/Templates'
$baseModulesLibrary = 'Modules'
$timerIntervalMinutes = 30
$columnPrefix = 'ALFA_'
$tenantAdminUrl = "https://techalfademo-admin.sharepoint.com"
$supportGroupName = "gurudattbn@techalfademo.onmicrosoft.com"
$targetEnv =  "DEV"
$siteDesignId = "513ea238-9d5f-4c6f-bd5e-a28081c7e557"
$tenantURL = "https://techalfademo.sharepoint.com"
$managedPath = "sites"
#>
# SETUP YOUR DEV CONFIG BELOW
<#
$clientId = "4cb98b17-75ba-452d-bd8a-7761d1b9998b";
$bas64Encoded = "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"
$certificatePassword = ConvertTo-SecureString -String "1qaz!QAZ" -AsPlainText -Force
$appAdTenant = "techalfademo.onmicrosoft.com"
$siteDirectorySiteUrl = "https://techalfademo.sharepoint.com/sites/collaborationlanding/collaboration"
$siteDirectoryList = '/Lists/Sites'
$templateConfigurationsList = '/Lists/Templates'
$baseModulesLibrary = 'Modules'
$timerIntervalMinutes = 30
$columnPrefix = 'ALFA_'
$tenantAdminUrl = "https://techalfademo-admin.sharepoint.com"
$supportGroupName = "gurudattbn@techalfademo.onmicrosoft.com"
$targetEnv =  "DEV"
$siteDesignId = "513ea238-9d5f-4c6f-bd5e-a28081c7e557"
$tenantURL = "https://techalfademo.sharepoint.com"
$managedPath = "sites"
#>
############################################################
# PRODUCTION SETUP


$clientId = $null;
$bas64Encoded = $null
$certificatePassword = $null
$appAdTenant = $null
$targetEnv = $null
$siteDesignId = $null
$tenantUrl = $null
$siteDirectorySiteUrl = $null
$siteDirectoryList = $null
$templateConfigurationsList = $null
$baseModulesLibrary = $null
$timerIntervalMinutes = $null
$columnPrefix = $null
$tenantAdminUrl = $null
$supportGroupName = $null
$managedPath = "sites"
$serviceCredentials = $null
$appCert = Get-AutomationCertificate -Name "AzureAppCertificate"

if ($null -eq $clientId) {
    $clientId = Get-AutomationVariable -Name 'AppClientId'
}


if ($null -eq $certificatePassword) {
    $certificatePassword = Get-AutomationPSCredential -Name 'AzureAppCertPassword'
}
if ($null -eq $serviceCredentials) {
    $serviceCredentials = Get-AutomationPSCredential -Name 'ServiceAccountCredentials'
}
if ($null -eq $bas64Encoded) {
    # Export the certificate and convert into base 64 string
    $bas64Encoded = [System.Convert]::ToBase64String($appCert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12, $certificatePassword.Password))
}

if ($null -eq $appAdTenant) {
    $appAdTenant = Get-AutomationVariable -Name 'AppAdTenant'
}

if ($null -eq $tenantUrl ) {
    $tenantUrl = Get-AutomationVariable -Name 'TenantUrl'
}


if ($null -eq $siteDirectorySiteUrl) {
    $siteDirectorySiteUrl = Get-AutomationVariable -Name 'SiteDirectorySiteUrl'
}

if ($null -eq $siteDirectoryList) {
    $siteDirectoryList = Get-AutomationVariable -Name 'SiteDirectoryList'
}

if ($null -eq $templateConfigurationsList) {
    $templateConfigurationsList = Get-AutomationVariable -Name 'TemplateConfigurationsList'
}

if ($null -eq $baseModulesLibrary) {
    $baseModulesLibrary = Get-AutomationVariable -Name 'BaseModulesLibrary'
}

if ($null -eq $timerIntervalMinutes) {
    $timerIntervalMinutes = Get-AutomationVariable -Name 'TimerIntervalMinutes'
}

if ($null -eq $columnPrefix) {
    $columnPrefix = Get-AutomationVariable -Name 'ColumnPrefix'
}

if ($null -eq $tenantAdminUrl) {
    $tenantAdminUrl = Get-AutomationVariable -Name 'TenantAdminUrl'
}

if ($null -eq $supportGroupName) {
    $supportGroupName = Get-AutomationVariable -Name 'SupportGroupName'
}

if ($null -eq $targetEnv) {
    $targetEnv = Get-AutomationVariable -Name 'TargetEnv'
}

if ($null -eq $siteDesignId) {
    $siteDesignId = Get-AutomationVariable -Name 'SiteDesignId'
}


if ( $null -eq $timerIntervalMinutes ) {
    # Developer tenant      
    # $directorySiteUrl = "/sites/directoryNext"b
    $timerIntervalMinutes = 30
}
    
$propertybagAlternativeList = 'PropertyBagAlternatives'
$propBagTemplateInfoStampKey = "_PnP_CollaborationAppliedTemplateInfo"
$propBagMetadataStampKey = "ProjectMetadata"
    
    
$urlToSiteDirectory = "$siteDirectorySiteUrl$siteDirectoryList"
    
# In modern team site, there is no property bag support. There is a way to workaround it, but we are not using workaround
# Rather we will use SharePoint list and hide the list from end user
$siteMetadataToPersist = @([pscustomobject]@{DisplayName = "-SiteDirectory_SiteEditors-"; InternalName = "$($columnPrefix)SiteEditor" },
    [pscustomobject]@{DisplayName = "-SiteDirectory_SiteOwners-"; InternalName = "$($columnPrefix)SiteOwners" }
    [pscustomobject]@{DisplayName = "-SiteDirectory_Organization-"; InternalName = "$($columnPrefix)Organization" }
    [pscustomobject]@{DisplayName = "-SiteDirectory_InformationClassification-"; InternalName = "$($columnPrefix)InformationClassification" }
    [pscustomobject]@{DisplayName = "-SiteDirectory_ProjectManager-"; InternalName = "Project_x0020_Manager" }
    [pscustomobject]@{DisplayName = "-SiteDirectory_Template-"; InternalName = "$($columnPrefix)TemplateConfig" }
)

#endregion

#Region Methods


#This method creates New Modern Team site (GROUP#0) if not present and sets site status as Either Active or Failed
#If failed, It sends mail to business owner's email id.
#NOTE: https://github.com/SharePoint/PnP-Sites-Core/issues/1401
#Currently not using $owners and $siteEditors
function EnsureSite {
    Param (
        [string]$siteEntryId,
        [string]$title,
        [string]$url,
        [string]$namealias,
        [string]$description = "",
        [string]$siteCollectionAdmin,
        [String[]]$ownerAddresses,
        [bool]$accesslevel,
        [string]$classification
    )

    try {
   
        Write-Output "Entered EnsureSite"
        Write-Output "Starting..."
       

            Connect-AzureADAppOnly -Url $tenantAdminUrl
            $site = Get-PnPTenantSite -Url $url -ErrorAction SilentlyContinue
 
            if ($null -eq $site) {
                Write-Output "Site at $url does not exist - let's create it"

                # Create site
                CreatePnPSite -title $title -url $newSiteUrl -namealias $nameAlias -description $description -accesslevel $isPublic -classification $informationclassification -ownerAddresses $ownerAddresses


                #If SiteStatus is Failed, due to some error site is not created
                if ($global:siteStatus -eq "Failed") {
                    # send e-mail
                    SendFailEmail -toEmail $ownerAddresses -itemID $siteEntryId
                    Write-Output "Setting site status to Failed"
                    UpdateStatus -id $siteEntryId -status 'Failed'
                    return;
                }        
                Start-Sleep -s 60 # extra sleep before setting site col admins
            }
            elseif ($site.Status -ne "Active") {
                Write-Output "Site at $url already exist"
                while ($true) {
                    Connect-AzureADAppOnly -Url $tenantAdminUrl
                    # Wait for site to be ready
                    $site = Get-PnPTenantSite -Url $url
                    if ( $site.Status -eq "Active" ) {
                        break;
                    }
                    Write-Output "Site not ready"
                    Start-Sleep -s 20
                }
                Start-Sleep -s 60 # extra sleep before setting site col admins
            }

            #Connect -Url $tenantAdminUrl
            Connect-AzureADAppOnly -Url $tenantAdminUrl
            $site = Get-PnPTenantSite -Url $Siteurl_new
            if ( $null -ne $site ) {
                $global:siteStatus = "Active"
                Write-Output "Site Url $($site.Url)"
            }
            else {
                $global:siteStatus = "Failed"
            }

        

    }
    catch {
        # Script error
        Write-Error "An error occurred: $($PSItem.ToString())"
    }
}

#US 135706 Collaboration job - Bug fix/improvements
function SendFailEmail($toEmail, $itemID) {
    # send e-mail
    Connect-AzureADAppOnly -Url $siteDirectorySiteUrl
    $web = Get-PnPWeb -Includes ServerRelativePath
    $mailHeadBody = GetMailContent -email $ownerAddresses -mailFile "fail" -relativeUrl $web.ServerRelativePath.DecodedUrl
    #Connect-AzureADAppOnly -Url $tenantAdminUrl
    Write-Output "Sending fail mail to $ownerAddresses"
    $requestItemUrl = "$siteDirectorySiteUrl$siteDirectoryList/DispForm.aspx?ID=$($siteEntryId)"
    Write-Output "Command : Send-PnPMail -To $($ownerAddresses) -Subject $($mailHeadBody[0]) -Body $($mailHeadBody[1] -f $requestItemUrl)"
    Send-PnPMail -To $ownerAddresses -Subject $mailHeadBody[0] -Body ($mailHeadBody[1] -f $requestItemUrl)
}

#Update Site request status
function UpdateStatus($id, $status) {
    #Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Connect-AzureADAppOnly -Url "$siteDirectorySiteUrl"
    Set-PnPListItem -List $siteDirectoryList -Identity $id -Values @{"$($columnPrefix)SiteStatus" = $status } -ErrorAction SilentlyContinue >$null 2>&1
}

<#
This method Sync changed/updated metadata from Site request form to respetive site
#>
function SyncMetadata($siteItem, $siteUrl, $urlToDirectory, $title, $description) {
    try {
        $itemId = $siteItem.Id
        $editFormUrl = "$urlToDirectory/EditForm.aspx?ID=$itemId" + "&Source=$siteUrl/SitePages/Home.aspx"

        $metadataJson = CreateMetadataPropertyValue -siteItem $siteItem -editFormUrl $editFormUrl -siteMetadataToPersist $siteMetadataToPersist

        #Connect -Url $siteUrl
        Connect-AzureADAppOnly -Url $siteUrl
        Write-Output "`tPersisting project metadata to $siteUrl - $metadataJson"
        $listItem = Get-PnPListItem -List $propertybagAlternativeList -Id 1 -ErrorAction SilentlyContinue

        $strOwners = New-Object System.Collections.ArrayList;
        $strEditors = New-Object System.Collections.ArrayList;

        if ( $null -eq $listItem ) {
     
            $listItemAdded1 = Add-PnPListItem -List $propertybagAlternativeList -Values @{"Title" = $propBagMetadataStampKey; "PropertyBagValuesJSON" = $metadataJson }
            Write-Output "$($propBagMetadataStampKey) added"
            #siteOwner
            $siteOwners = @($siteItem["$($columnPrefix)SiteOwners"]) | Select-Object Email, LookupValue
            #US 135706 Collaboration job - Bug fix/improvements
            foreach ($User in $siteOwners) {
                if ($User.Email -notlike "*leaver*" ) {
                    $strOwners.Add(($User.LookupValue + "|" + $User.Email));
                }
                else {
                    Write-Output "Site Owner $($User.Email) left Alfalaval ,skipping from owners list"
                }
         
            }

            if ($strOwners.Count -gt 0) {
                $mainOwner = @($strOwners)[0];
            }
            else {
                $mainOwner = "";
            }
      
            $listItemAdded2 = Add-PnPListItem -List $propertybagAlternativeList -Values @{"Title" = "SiteOwner"; "PropertyBagValuesJSON" = $mainOwner }
            Write-Output "SiteOwner added hidden list"

            #siteEditor
            $siteEditors = @($siteItem["$($columnPrefix)SiteEditor"]) | Select-Object Email, LookupValue
            #US 135706 Collaboration job - Bug fix/improvements
            foreach ($User in $siteEditors) {
                if ($User.Email -notlike "*leaver*" ) {
                    $strEditors.Add(($User.LookupValue + "|" + $User.Email));
                }
                else {
                    Write-Output "Site Editor $($User.Email) left Alfalaval ,skipping from editors list"
                }
         
            }

            if ($strEditors.Count -gt 0) {
                $mainEditor = @($strEditors)[0];
            }
            else {
                $mainEditor = "";
            }
            $listItemAdded3 = Add-PnPListItem -List $propertybagAlternativeList -Values @{"Title" = "SiteEditor"; "PropertyBagValuesJSON" = $mainEditor }
            Write-Output "SiteEditor added hidden list"
        }

        if ($null -ne $title -and $null -ne $description ) {
            Set-PnPWeb -Title $title -Description $description
        }

    }
    catch {
        # Script error
        Write-Error "An error occurred: $($PSItem.ToString())"
    }
}

<#
This method sets Site Url to list item
#>
function SetSiteUrl($siteItem, $siteUrl, $title) {
    Connect-AzureADAppOnly -Url "$siteDirectorySiteUrl"
    Write-Output "Setting site URL to $siteUrl"
    Set-PnPListItem -List $siteDirectoryList -Identity $siteItem.Id -Values @{"$($columnPrefix)SiteURL" = "$siteUrl, $title" } -ErrorAction SilentlyContinue >$null 2>&1
}

function SetSiteStatusAvailable($id, $status) {
    #Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Connect-AzureADAppOnly -Url "$siteDirectorySiteUrl"
    Set-PnPListItem -List $siteDirectoryList -Identity $id -Values @{"$($columnPrefix)SiteStatus" = $status } -ErrorAction SilentlyContinue >$null 2>&1
}

<#
This method gets Template information from Site request and gets actual OpenXML file from Modules
and Invoke PnP Provison template to site
#>
function ApplyTemplateConfigurations($url, $siteItem, $templateConfigurationItems, $baseModuleItems, $title, $siteStatus) {
    if ($siteStatus -ne 'Available') {
        #Connect -Url $url
        Connect-AzureADAppOnly -Url $url
        #ConnectWithCredentials -Url $url -userName $userName -pw $pwPlainText
        $templateConfig = $siteItem["$($columnPrefix)TemplateConfig"]
        if ( $null -ne $templateConfig ) {
            $chosenTemplateConfig = $templateConfigurationItems | ? Id -eq $templateConfig.LookupId
            if ( $null -ne $chosenTemplateConfig ) {
                $chosenBaseTemplate = $chosenTemplateConfig["$($columnPrefix)ALFA_Modules"]
                if ( $null -ne $chosenBaseTemplate) {
                    $pnpTemplate = $baseModuleItems | ? Id -eq $chosenBaseTemplate.LookupId
                    $alfaTenantUrl = $tenantAdminUrl.Replace("-admin.sharepoint", ".sharepoint")
                    $pnpUrl = $alfaTenantUrl + $pnpTemplate["FileRef"]
                    ApplyTemplate -url $url -templateUrl $pnpUrl -templateName $pnpTemplate["FileLeafRef"] $title
                }
            }
        }
        else {
            Write-Output "Template not found"
        }
    }
}

#This method applies OfficeDevPnP Provisioning template (.PnP) to newly created site, followed by non templatized solution and sets the property bag of the site request
function ApplyTemplate([string]$url, [string]$templateUrl, [string]$templateName, [string]$title) {
    Connect-AzureADAppOnly -Url $url
    $appliedTemplates = Get-PnPPropertyBag -Key $propBagTemplateInfoStampKey
    if ((-not $appliedTemplates.Contains("|$templateName|") -or $Force)) {
        Write-Output "`tApplying template $templateName to $url"
        #Check context of connectedUrl is similar to parameter, If yes, respective apply .pnp template
        $ctx = Get-PnPContext
        if ($ctx.Url -eq $url) {
            Invoke-PnPSiteTemplate -Path $templateUrl
        }
    }
    else {
        Write-Output "`tTemplate $templateName already applied to $url"
    }
}

<#
  This method ensures AD security group and set Owners / members of the group
#>
function EnsureADSecurityGroups([string]$url, [string]$nameAlias, [string[]]$owners, [string[]]$siteEditors, [bool]$isPublic, [string]$siteStatus) {
        
    # Add owners to member group
    $allMembers = ($owners + $siteEditors) | select -Unique
  
    # Get group from site
    Connect-AzureADAppOnly -Url $url
    $site = Get-PnPSite -Includes Id, GroupId
    [string]$groupSiteId = $site.GroupId
    Write-Output "Site Group Id :  $groupSiteId"

    # Update group
    if ($siteStatus -ne 'Available') {
        Connect-AzureADAppOnly -Url $url
        $owners | % { if (-not [String]::IsNullOrEmpty($_) ) { Add-PnPMicrosoft365GroupOwner -Identity $groupSiteId -Users $_ -ErrorAction SilentlyContinue >$null 2>&1 } }

        #NOTE : Owners and members both needs to be added members, Otherwise planner does not work well for Site owners by design. 
        $allMembers | % { if (-not [String]::IsNullOrEmpty($_)) { Add-PnPMicrosoft365GroupMember -Identity $groupSiteId -Users $_ -ErrorAction SilentlyContinue >$null 2>&1 } }
        Write-Output "Owners and members are added successfully"
    }

}

#SHARED
<#
Connect to SharePoint Online using Azure AD Authentication with base64Encoded string
#>
function Connect-AzureADAppOnly([string]$Url, [boolean]$Force = $false) {
    try {
        if ( $null -ne $Url ) {
            if ($Url -eq $Global:lastContextUrl -and (-Not $Force)) {
                return
            }
            else {
                # DEV ONLY
                <# Connect-PnPOnline -ClientId $clientId -CertificateBase64Encoded $bas64Encoded `
            -CertificatePassword $certificatePassword `
            -Url $Url -Tenant $appAdTenant #>
                # PRODUCTION
                Connect-PnPOnline -ClientId $clientId -CertificateBase64Encoded $bas64Encoded `
                    -CertificatePassword $certificatePassword.Password `
                    -Url $Url -Tenant $appAdTenant
            }
        }
        $Global:lastContextUrl = $Url;
    }
    catch {
        Write-Error "An error occurred: $($PSItem.ToString())"
    }
}

#Get/return Recently updated/newly created new item from Site Request list
function GetRecentlyUpdatedItems($IntervalMinutes) {
    Connect-AzureADAppOnly -Url "$siteDirectorySiteUrl"
    $date = [DateTime]::UtcNow.AddMinutes(-$IntervalMinutes).ToString("yyyy\-MM\-ddTHH\:mm\:ssZ")
    $recentlyUpdatedCaml = @"
<View>
  <Query>
      <Where>
       <And>
          <Gt>
              <FieldRef Name="Modified" />
              <Value IncludeTimeValue="True" Type="DateTime" StorageTZ="TRUE">$date</Value>
          </Gt>
          <And>
            <Neq>
                <FieldRef Name='ALFA_SiteStatus' />
                <Value Type='Choice'>Failed</Value>
            </Neq>
            <Neq>
                <FieldRef Name='ALFA_SiteStatus' />
                <Value Type='Choice'>Draft</Value>
            </Neq>
          </And>
        </And>
      </Where>
      <OrderBy>
          <FieldRef Name="Modified" Ascending="False" />
      </OrderBy>
  </Query>
  <ViewFields>
      <FieldRef Name="ID" />
      <FieldRef Name="ALFA_SiteStatus" />
      <FieldRef Name="ALFA_SiteType" />
  </ViewFields>
</View>
"@
    if ($Force) {
        return @(Get-PnPListItem -List $siteDirectoryList)    
    }
    else {
        return @(Get-PnPListItem -List $siteDirectoryList -Query $recentlyUpdatedCaml)
    }    
}
function UpdateContentType($siteItem)
{
    $ct = $null
    if($siteItem["ALFA_SiteType"] -eq "Collaboration Site"){
        $ct = "Collaboration site"
    }
    elseif($siteItem["ALFA_SiteType"] -eq "Project Site"){
        $ct = "Project Site"
    }
    if($null -ne $ct){
        Write-Output "Updating content type for $($siteItem['ID'])"
		If($ct -eq "Collaboration site")
		{
        	return Set-PnPListItem -List Sites -Identity $siteItem -ContentType $ct -Values @{"Project_x0020_Manager"= $null} -SystemUpdate
		}
		else{
			return Set-PnPListItem -List Sites -Identity $siteItem -ContentType $ct -SystemUpdate
		}
    }
    else{
        Write-Output "Error Updating content type for $($siteItem['ID'])"
        return $null
    }
}
#Update/Choose Template based on Content type
function UpdateTemplateByContentType($siteItem) {
    try {
        if ($siteItem["$($columnPrefix)SiteStatus"] -ne 'Available') {
            $templateLookUpNo = $null;
            $prop = Get-PnPProperty -ClientObject $siteItem -Property ContentType
            if ($null -ne $prop) {
                $propname = $prop.Name
                $correctTemplateCaml = "
              <View>
                 <Query>
                     <Where>
                         <Contains>
                            <FieldRef Name='Title' />
                             <Value Type='Text'>$propname</Value>
                         </Contains>
                            </Where>
                         </Query>
                       <ViewFields>
                           <FieldRef Name='ID' />
                       </ViewFields>
              </View>
              "
                $templateLookUpNo = Get-PnPListItem -List 'Project Templates' -Query $correctTemplateCaml | Select Id
                <# if($prop.Name -eq "Collaboration site"){
                  #Collaboration
                  #$templateLookUpNo = "3"
                  $templateLookUpNo = "1"
                  Get-PnPListItem -List "Project Templates" -Query 
              }
              elseif($prop.Name -eq "Project Site"){
                  #Project
                 # $templateLookUpNo = "4"
                  $templateLookUpNo = "2"
              }#>
            }
          
            return Set-PnPListItem -List Sites -Identity $siteItem -Values @{"$($columnPrefix)TemplateConfig" = $templateLookUpNo.Id } -SystemUpdate
            Write-Output "Updated the Template of list item successfully"
        }
    }
    catch {
        # Script error
        Write-Error "An error occurred: $($PSItem.ToString())"
    }
}

#Get Prefix from Content Type name
function GetPreFixFromContentTypeName($ContentType) {
    $prefix = ""
    if ($ContentType -ne $null) {
        if ($ContentType.Name -eq "Collaboration site") {
            #Collaboration
            if ($targetEnv -ne "Production") {
                $prefix = $targetEnv + "-" + "Collaboration"
            }
            else {
                $prefix = "Collaboration"
            }
        }
        elseif ($ContentType.Name -eq "Project Site") {
            #Project
            if ($targetEnv -ne "Production") {
                $prefix = $targetEnv + "-" + "Project"
            }
            else {
                $prefix = "Project"
            }
        }
    }
    return $prefix
}


#Get Unique Site Url from Site Title
function GetUniqueUrlFromName($title, $ContentType) {
   # Write-Output "\nGettig unique name and URL for $title"
    #Connect -Url $tenantAdminUrl
    Connect-AzureADAppOnly -Url $tenantAdminUrl
    #ConnectWithCredentials -Url $tenantAdminUrl -userName $userName -pw $pwPlainText
    $prefix = GetPreFixFromContentTypeName -ContentType $ContentType
    $cleanName = $title -replace '[^a-z0-9]'
    if ($cleanName.length -lt 5) { 
        if ($cleanName.length -eq 0) {
            # [Type]-[Date] like "Project-12062019"
            $cleanName = (Get-Date).ToString("ddMMyyyy"); 
        }
        else {
            # [Type]-[Characters_After_Cleaning]-[Date] like "Project-1A2B-12062019"
            $cleanName += "-" + (Get-Date).ToString("ddMMyyyy");     
        }
    }    
    $cleanName = $prefix + '-' + $cleanName
    # Issue ID 24 in http://work.alfalaval.org/tools/shareservicesite/Lists/Share%20O365%20Issues/AllItems.aspx
    # MailNickName character limit is 64. so to be on safer side, truncate it at 59
    if ($cleanName.length -ge 59) {
        $cleanName = $cleanName.Substring(0, 58)
    }
    if ([String]::IsNullOrWhiteSpace($cleanName)) {
        $cleanName = "team"
    }
    $alfaTenantUrl = $tenantAdminUrl.Replace("-admin.sharepoint", ".sharepoint")
    $url = "$alfaTenantUrl/$managedPath/$cleanName"
    #$newData =@()
    $doCheck = $true
    $counter = 1
    #Write-Output "\nCounter $counter"
    $newTitle = $title
    $newurl = $url
    while ($doCheck) {
        #stderr to stdout if it's error
        #Write-Output "\nGetting site with url $newurl"
        $newSite = Get-PnPTenantSite -Url $newurl -ErrorAction SilentlyContinue
        $adGroup =$null
       try{
           
          # Write-Output "\nGetting ad group with title $newTitle"
            $adGroup = Get-PnPAzureADGroup -Identity $newTitle -ErrorAction SilentlyContinue
        }
        catch{
            #Write-Output "\nError:While fetching o365 group from AD $_.Exception.Message"
        }
    
        if ($newSite -ne $null -or $adGroup -ne $null) {
            
            $newurl = $url + $counter
            $newTitle = $title + $counter
            #Write-Output $newTitle
            $counter++
        }
        else {
            $doCheck = $false
        }
    }
   # Write-Output "Function complete final values $newTitle $newurl"
    
    return $newTitle+"|"+$newurl
}

<#
Get Login Name
#>
function GetLoginName {
    Param(
        [int]$lookupId
    )
    #Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Connect-AzureADAppOnly -Url "$siteDirectorySiteUrl"
    $user = Get-PnPUser -Identity $lookupId
    return $user.LoginName    
}

<#
Get User Email
#>
function GetUserEmail {
    Param(
        [string]$loginName
    )
    #   Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Connect-AzureADAppOnly -Url "$siteDirectorySiteUrl"
    $user = Get-PnPUser -Identity $loginName
    return $user.Email
}

<#
Get User UPN (UserPrincipalName)
There is no direct method,so getting UPN value by string operation
#>
function GetUserUPN {
    Param(
        [string]$loginName
    )
    $upnName = ""
 
    Connect-AzureADAppOnly -Url "$siteDirectorySiteUrl" 
    $user = Get-PnPUser -Identity $loginName
    if ($null -ne $user) {
        $upnName = $user.LoginName.Substring($user.LoginName.LastIndexOf('|') + 1 )
    }
    return $upnName
}


function CreatePnPSite {
    Param (
        [string]$title,
        [string]$url,
        [string]$namealias,
        [string]$description = "",
        [bool]$accesslevel,
        [string]$classification,
        [String[]]$ownerAddresses
    )   

    $attemptCount = 3;
    [int]$waitTime = 1;
    if ([int]::TryParse($createSiteMaxWaitingTime, [ref]$waitTime) -eq $true) {
        $attemptCount = $waitTime * 3; # 3 attempts per minute
    }
    
    # Connect
    Connect-AzureADAppOnly -Url $tenantAdminUrl
    # Create site
    try {
        $global:Siteurl_new = New-PnPSite -Type TeamSite -Title $title -Alias $namealias -Description $description -IsPublic:$accesslevel -Owners $serviceCredentials.UserName -ErrorVariable errVar -ErrorAction Stop 
        # Site was created. Return site
        Write-Output "New-PnPSite: Site creation executed";
        $global:siteStatus = "Active";
        #$url = New-PnPSite -Type $type -Title $title -alias $namealias -Connection $adminConnection -IsPublic:$isPublic -Lcid 1030 -ErrorAction Stop
        Write-Output ("New-PnPSite: the original url returned from site creation was [{0}]" -f $Siteurl_new)
    }
    catch {
        Write-Output ("New-PnPSite: there was an error creating the site: [{0}]" -f $_)
        $message = $_.Exception.Message
        Write-Verbose ("New-PnPSite catch: Message [{0}]" -f $message)
        switch -Wildcard ($message) {
            "*CreateGroupEx*" {
                Write-Output "New-PnPSite: we received the 'delayed' status, so site is probably created but creation is delayed."
                # parse json in error
                $newSiteJson = $message | ConvertFrom-Json
                $siteStatus = $newSiteJson.d.CreateGroupEx.SiteStatus
                Write-Output ("The group ID returned was [{0}], SiteStatus was [{1}]" -f $newSiteJson.d.CreateGroupEx.GroupId, $siteStatus)
                if ($siteStatus -eq 1 -and (Test-GuidValidAndNotEmpty -Guid $newSiteJson.d.CreateGroupEx.GroupId) ) {
                    # We have a valid GroupId
                    
                }
                else {
                    # rethrow
                    throw "New-PnPSite: CreateGroupEx with bad status and/or invalid group id. Aborting!"
                }
                while ($attemptCount -gt 0) {
                    Connect-AzureADAppOnly -Url $tenantAdminUrl
                    $site = Get-PnPTenantSite -Url $Siteurl_new -ErrorAction SilentlyContinue
                    if ($site.Status -eq "Active") {
                        [console]::WriteLine("New-PnPSite: Site was created successfully.");
                        $global:siteStatus = "Active";
                        return;
                    }
                    $attemptCount--
                    [console]::WriteLine("New-PnPSite: Site not ready. Remaining attempts: {0}", $attemptCount);
                    Start-Sleep -s 20
                }
                [console]::WriteLine("New-PnPSite: Waiting time is over. Site not ready.");
                $global:siteStatus = "Failed";
                continue;   
            }
            "*A task was canceled*" {
                # This is a known issue https://github.com/SharePoint/sp-dev-docs/issues/1712
                # This can apparently be ignored so continue processing!
                continue;
            }
            "*(403)*Forbidden*" {
                Write-Output "New-PnPSite: we received the '(403) Forbidden' status, so site was not created."
                # we have seen a few 403 even though admin user is used
                # Rethrow exception
                throw $_
                continue;
            }
            "*The group alias already exists*" {
                Write-Output "New-PnPSite:The group alias already exists,Try with different name"
                $global:siteStatus = "Failed";
            }
            "Cannot bind parameter 'Type'*" {
                $global:siteStatus = "Failed";
            }
            Default {
                # Rethrow and catch error in outer catch
                #throw $_
                $global:siteStatus = "Failed";
                continue;    
            }
        }
    }
    # Site was created. Return site
    # [console]::WriteLine("New-PnPSite: Site creation executed");
    # $global:siteStatus = "Active";
    return;
}

# Disable external sharing in Outlook online
# By default Office 365 group is public by default (at least when writing this code)., eventhough External sharing is disabled
# at Office 365 group explicitly ( SharingCapability = Disabled ), through Outlook online its possible to invite external users
# since project requirement is not no external sharing by default, we are explicitly disabling Guest invite in Outlook online.
# Note: Graph Api needs Directory.ReadWrite.All privilegde to perform this action.
function Disable-ExternalSharing([string]$url, [string]$namealias) {
   
    if ( $null -ne $url -and $null -ne $namealias ) {
        Connect-AzureADAppOnly -Url "$siteDirectorySiteUrl" 
        #get group by id
        $group = Get-PnPMicrosoft365Group -Identity $namealias
        #Get the access token
        $token = Get-PnPAccessToken
        #Prepare headers
        $headers = @{"Content-Type" = "application/json" ; "Authorization" = "Bearer " + $token }
        #The directory template to set the policy. Group.Unified.Guest has id 08d542b9-071f-4e16-94b0-74abb372e3d9
        $templateDeny = @"
         {
           "templateId": "08d542b9-071f-4e16-94b0-74abb372e3d9",
           "values": [
             {
               "name": "AllowToAddGuests",
               "value": "False"
             }
           ]
         }
"@
        #Graph URL to add settings to the group
        $url = "https://graph.microsoft.com/v1.0/groups/$($group.GroupId)/settings"
        #Apply the template, and wait for a 204
        Invoke-WebRequest -Method Post -Uri $url -Headers $headers -Body $templateDeny -UseBasicParsing
    }
}

#Enables or disables the External sharing Policy of Modern Team Site (aka Microsoft 365 groups)
function EnableOrDisableExternalSharing([string]$url, [bool]$externalSharing, [string]$namealias) {
    if ($externalSharing) {
        Connect-AzureADAppOnly -Url "$siteDirectorySiteUrl" 
        Set-PnPTenantSite -Url $url -SharingCapability ExternalUserSharingOnly
        Write-Output "Extnernal sharing has been enabled successfully"
    }
    else {
        # Check Current sharing capability, If Disabled, dont do anything, If enabled, Disable it.
        # Note : By default, external sharing is enabled in office 365 group related site collection
        # Note : External sharing opton is changed over the period to True to False, all existing external users will still remain. Thats Out Of The Box Behaviour.
        Connect-AzureADAppOnly -Url "$siteDirectorySiteUrl"
        $site = Get-PnPTenantSite -Url $url -Detailed
        if ($site.SharingCapability -ne "Disabled") {
            Set-PnPTenantSite -Url $url -SharingCapability Disabled -DenyAddAndCustomizePages:$true
            echo "Extnernal Sharing and Site Scripts has been disabled successfully"
            Disable-ExternalSharing -url $url -namealias $namealias
            echo "Guest inviting disabled at Outlook online level successfully"
        }
        else {
            Disable-External-Sharing -url $url -namealias $namealias
            echo "Guest inviting enabled at Outlook online level successfully"
        }
    }
}

<#
Disable the members of the site to share data externally
TODO (08/07/2021) : As per my test, below method not really reflecting (which is good for us). Remove it ??
#>

<#
function DisableMemberSharing([string]$url){
    #Connect -Url $url
    Connect-AzureADAppOnly -Url "$siteDirectorySiteUrl"
    $web = Get-PnPWeb
    $canShare = Get-PnPProperty -ClientObject $web -Property MembersCanShare
    if($canShare) {
        Write-Output "`tDisabling members from sharing"
        $web.MembersCanShare = $false
        $web.Update()   
        $web.Context.ExecuteQuery()
    }
}
#>

# Invoke PnP Site design
function Invoke-SiteDesign([string]$url) {
    if ($null -ne $url) {
   
        Connect-AzureADAppOnly -Url "$tenantAdminUrl"
        Invoke-PnPSiteDesign -Identity $siteDesignId -WebUrl $url
        Write-Output "Site design to apply themes applied successfully"
        
    }
}


<#
This creates Key Value Metadata property $propBag
#>
function CreateKeyValueMetadataObject($key, $fieldType, $fieldValue, $fieldInternalName) {
    $value = @{
        'Type'      = $fieldType
        'Data'      = $fieldValue
        'FieldName' = $fieldInternalName
    }
    $properties = @{
        'Key'   = $key
        'Value' = New-Object -TypeName PSObject -Prop $value
    }

    return New-Object -TypeName PSObject -Prop $properties
}

<#
This creates Metadata property value
#>
function CreateMetadataPropertyValue($siteItem, $editFormUrl, $siteMetadataToPersist) {
    $metadata = @();
    $siteMetadataToPersist | % {
        $fieldName = $_.InternalName
        $fieldDisplayName = $_.DisplayName
        $fieldValue = $siteItem[$fieldName]
        if ($fieldValue -ne $null) {
            $valueType = $fieldValue.GetType().Name
            $valueData = $fieldValue.ToString()
            if ($valueType -eq "FieldUserValue") {
                $valueData = "$($fieldValue.LookupId)|$($fieldValue.LookupValue)|$($fieldValue.Email)"
            }
            elseif ($valueType -eq "FieldUserValue[]") {
                $valueData = @($fieldValue | % { "$($_.LookupId)|$($_.LookupValue)|$($_.Email)" }) -join "#"
            }
            elseif ($valueType -eq "FieldUrlValue") {
                $valueData = $fieldValue.Url + "," + $fieldValue.Description
            }
            elseif ($valueType -eq "FieldLookupValue") {
                $valueData = "$($fieldValue.LookupId)|$($fieldValue.LookupValue)"
            }
            elseif ($fieldValue.Label -ne $null) {
                $valueData = $fieldValue.Label
                $valueType = "TaxonomyFieldValue"
            }
            $metadata += (CreateKeyValueMetadataObject -key $fieldDisplayName -fieldType $valueType -fieldValue $valueData -fieldInternalName $fieldName)
        }
    }
    $metadata += (CreateKeyValueMetadataObject -key "-SiteDirectory_ShowProjectInformation-" -fieldType "FieldUrlValue" -fieldValue $editFormUrl -fieldInternalName "NA")

    return ConvertTo-Json $metadata -Compress

}

# Add User to Site Collection Administrator
function AddUserToSiteAdmins([string]$url, [string]$usrName) {
    # Connect to the site
    Connect-AzureADAppOnly -Url $url
    # Split users (if multiple)
    $usrArray = $usrName.Split(',').Trim()
    # Add user/group to site admins
    Add-PnPSiteCollectionAdmin -Owners $usrArray -WarningAction SilentlyContinue -WarningVariable WarningMsg
    Add-PnPSiteCollectionAdmin -Owners $serviceCredentials.UserName -WarningAction SilentlyContinue -WarningVariable WarningMsg
    # Log
    if ($WarningMsg) {
        Write-Output "WARNING adding user to site administrators"
        Write-Output "Warning: $WarningMsg"
    }
    else {
        Write-Output "$usrName is added to site administrators successfully"
    }
}
function ApplySensitivityLabel([string] $labelTitle,[string] $siteURL){
    Write-Output "Applying sensitivity label $labelTitle to site: $siteURL"
    $labelGUID = "";
    #$Username = "<service_account_email>"
    #$Password = "<service_account_password>"
    #[SecureString]$SecurePass = ConvertTo-SecureString $Password -AsPlainText -Force
    #[System.Management.Automation.PSCredential]$PSCredentials = New-Object System.Management.Automation.PSCredential($Username, $SecurePass)
    switch ($labelTitle) {
        "Public" 
        {
            $labelGUID = Get-AutomationVariable -Name 'SensitivityLabelPublic'
        }
        "Business" 
        {
            $labelGUID = Get-AutomationVariable -Name 'SensitivityLabelBusiness'
        }
        "Confidential" 
        {
            $labelGUID = Get-AutomationVariable -Name 'SensitivityLabelConfidential'
        }
        "Strictly Confidential" 
        {
            $labelGUID = Get-AutomationVariable -Name 'SensitivityLabelStrictlyConfidential'
        }
    }
    if($null -ne $labelGUID)
    {
        Write-Output "Label GUID: $labelGUID"
        Connect-PnPOnline -Url $siteURL -Credentials $serviceCredentials
        Set-PnPSiteSensitivityLabel -Identity $labelGUID -ErrorAction SilentlyContinue
        Write-Output "Label applied."
    }
    else
    {
        Write-Output "Label GUID is empty. Please check runbook variable."
    }
}
function GetGraphToken() {
    $Token = Get-MsalToken -ClientId $clientId -TenantId $appAdTenant -ClientCertificate $appCert
    return $Token.AccessToken
}
function CreateTeamsForNewSite([string]$url) {
    try{
        Write-Output "Getting group ID for teams"
        Connect-AzureADAppOnly -Url $url
        # Get Group ID from newly created site
        $site = Get-PnPSite -Includes Id, GroupId
        $group_id = $site.GroupId.Guid
        Write-Output "Group Id: $group_id"
        # Get access token for graph api using MSAL module
        Write-Output "Getting access token for graph api"
        $graphToken = GetGraphToken
        Write-Output "Token: $graphToken"

        #Generating headers for graph api
        $Headers = @{
            "Authorization" = "Bearer $($graphToken)"
            "Content-type"  = "application/json"
        }

        #creating object for teams setting.
        $array = @{}
        $data1 = @{"allowCreateUpdateChannels"=$true;"allowCreatePrivateChannels"=$false;}
        $array.Add("memberSettings",$data1)
        $data2 = @{"allowUserEditMessages"=$true;"allowUserDeleteMessages"=$true;}
        $array.Add("messagingSettings",$data2)
        $data3 = @{"allowGiphy"=$true;"giphyContentRating"="strict";}
        $array.Add("funSettings",$data3)
        $payload = $array | ConvertTo-Json

        $apiUri = "https://graph.microsoft.com/v1.0/groups/$group_id/team"
        $response = Invoke-WebRequest -Method PUT -Uri $apiUri -Headers $Headers -UseBasicParsing -Body $payload
    }
    catch {
        Write-Output "Exception creating teams $($_.Exception.Message)"
    }

}
#Adds Introduction text to site from provided site description
function Update-SiteIntroductionText {
    param(
        [string]$pageName,
        [string]$pageText,
        [string]$url
    )
    #Add a delay as previous method called is Async.
    Start-Sleep -s 20
    $webpartInstanceId = $null
    #Connect -Url $url
    Connect-AzureADAppOnly -Url $url
    $webparts = Get-PnPPageComponent -Page $pageName
    $webparts | ForEach-Object {
        if ($_.GetType().Name -eq "PageText" -and $_.Section.Order -eq 1) {
            $webpartInstanceId = $_.InstanceId
        }
    }
    if ($null -ne $webpartInstanceId) {
        Set-PnPClientSideText -Page $pageName -InstanceId $webpartInstanceId -Text $pageText
        Write-Output "Page Introduction is updated successfully"
    }
  
}

#This method sends Site ready email to Site requestor cc'ing Business Owner
function SendReadyEmail() {
    Param(
        [string]$url,
        [string]$toEmail,
        [String[]]$ccEmails,
        [string]$title
    )
    try {
        # http://anoojnair.com/2016/07/the-email-message-cannot-be-sent-make-sure-the-email-has-a-valid-recipient/
        # Connecting to tenant roote site endpoint
        $alfaTenantUrl = $tenantAdminUrl.Replace("-admin.sharepoint", ".sharepoint")
        # Changes done while moving job to Azure Automation
        Connect-AzureADAppOnly -Url $siteDirectorySiteUrl
        $web = Get-PnPWeb -Includes ServerRelativePath
        if ( -not [string]::IsNullOrWhiteSpace($toEmail) ) {
            $mailHeadBody = GetMailContent -email $toEmail -mailFile "welcome" -relativeUrl $web.ServerRelativePath.DecodedUrl
        
            Write-Output "Sending ready mail to $toEmail and $ccEmails"
            Send-PnPMail -To $toEmail -Cc $ccEmails -Subject ($mailHeadBody[0] -f $title) -Body ($mailHeadBody[1] -f $title, $url)
        }
    }
    catch {
        Write-Output "Exception sending email $($_.Exception.Message)"
    }
}

<#
Return mail stream based on specific mail file
#>
function GetMailContent {
    Param(
        [string]$email,
        [string]$mailFile,
        [string]$relativeUrl
    )
    $ext = "en";
    if ($mail) {
        $ext = $email.Substring($email.LastIndexOf(".") + 1)
    }
    # Changes done while moving job to Azure Automation
    # Write-Output "Fetching email template from path : $($relativeUrl)/Shared Documents/MailTemplates/$($mailFile)-mail-$ext.txt"
    $file = Get-PnPFile -Url "$($relativeUrl)/Shared Documents/MailTemplates/$($mailFile)-mail-$ext.txt" -AsString
    #$filename = "$PSScriptRoot/resources/$mailFile-mail-$ext.txt"
    return $file.Split("|")
}

#endregion

#Region Script starts here
Write-Output @"
  AlfaLaval Site Provisioning engine starts here.
"@

try {
    
    $tenantURL = $tenantURL + $directorySiteUrl
    Connect-AzureADAppOnly -Url "$siteDirectorySiteUrl" -Force $true

    $templateConfigurationItems = @(Get-PnPListItem -List $templateConfigurationsList)
    $baseModuleItems = @(Get-PnPListItem -List $baseModulesLibrary)
    $siteDirectoryItems = GetRecentlyUpdatedItems -Interval $timerIntervalMinutes

    if (!$siteDirectoryItems -or ( $null -ne $siteDirectoryItems -and (0 -eq $siteDirectoryItems.Count))) {
        Write-Output "No site requests detected last $timerIntervalMinutes minutes"
    }
    Write-Output "Content type Update code start"
     #Iterate through all Requested sites list and Update content type based on site type selected.
     foreach ($siteItem in $siteDirectoryItems) {
        $updatedContentType = UpdateContentType($siteItem)
     }
     Start-Sleep -s 10
     Write-Output "Template Update code start"
    #Iterate through all Requested sites list and Update Respective template based on selected Content type
    foreach ($siteItem in $siteDirectoryItems) {
        #Below method updates Template of the request based on Content type
        # NOTE: In some places variables are assigned but not used. Thats because Azure Automation job expects every powershell command returns value and saving it to variable is neccessary.
       $updatedTemplate = UpdateTemplateByContentType($siteItem)
    }
   
    #Iterate through all Requested sites list and create site now
    foreach ($siteItem in $siteDirectoryItems) {
        try {
            Connect-AzureADAppOnly -Url "$siteDirectorySiteUrl" -Force $true
            #Get initial editor - which is needed for checks further down
            $siteItem = Get-PnPListItem -List $siteDirectoryList -Id $siteItem.ID -Fields "Id", "Title", "$($columnPrefix)SiteURL", "Editor", "Author", "$($columnPrefix)ProjectDescription",
            "$($columnPrefix)SiteStatus", "$($columnPrefix)SiteOwners", "$($columnPrefix)SiteEditor", "$($columnPrefix)AccessLevel", "$($columnPrefix)InformationClassification", "$($columnPrefix)TemplateConfig","ALFA_CreateTeams"
            if ( $null -ne $siteItem -and $siteItem -ne "") {
                # get title
                $title = $siteItem["Title"]
                $createTeams = $siteItem["ALFA_CreateTeams"];
                if ($null -eq $siteItem["$($columnPrefix)SiteURL"]) {
                    Write-Output "URL empty"
                    $prop = Get-PnPProperty -ClientObject $siteItem -Property ContentType
                    #$siteUrl = GetUniqueUrlFromName -title $title -ContentType $prop
                    Write-Output "Getting unique"
                    $newData= GetUniqueUrlFromName -title $title -ContentType $prop
                    $newTitle,$newSiteUrl=$newData.Split('|')
                    Write-Output "completed outside $newData"
                    $nameAlias = $newSiteUrl.Substring($newSiteUrl.LastIndexOf("/") + 1)
                }
                else {
                    #$siteUrl = $siteItem["$($columnPrefix)SiteURL"].Url
                    $newSiteUrl = $siteItem["$($columnPrefix)SiteURL"].Url
                    $nameAlias = $newSiteUrl.Substring($newSiteUrl.LastIndexOf("/") + 1)
  
                    # Skip edited item processing
                    Write-Output "$nameAlias skiped because not new site request"
                    continue
                }
      
                # get editor
                $editor = $siteItem["Editor"][0].LookUpValue;
                # get Ordered by
                $orderedByUser = $siteItem["Author"][0];
       
                # get Site description
                $description = $siteItem["$($columnPrefix)ProjectDescription"]
    
                # get Site Status
                $global:siteStatus = $siteItem["$($columnPrefix)SiteStatus"]
                #US 135706 Collaboration job - Bug fix/improvements
                # get Site Owners
                $ownersEmailAddress = @($siteItem["$($columnPrefix)SiteOwners"] | ? { -not [String]::IsNullOrEmpty($_.Email) -and $_.Email -notlike "*leaver*" } | select -ExpandProperty Email)
                #US 135706 Collaboration job - Bug fix/improvements
                # get Site Editors
                $siteEditorsEmailIds = @($siteItem["$($columnPrefix)SiteEditor"] | ? { -not [String]::IsNullOrEmpty($_.Email) -and $_.Email -notlike "*leaver*" } | select -ExpandProperty Email)
        
                ############ Code for Setting Access level #####################
                $isPublic = $false
                $acesslevel = $siteItem["$($columnPrefix)AccessLevel"]
    
    
                if ($acesslevel -eq "Private") {
                    $isPublic = $false
                }
                else {
                    $isPublic = $true
                }

                ############ Code for Setting Information classification level #####################
                $informationclassification = $siteItem["$($columnPrefix)InformationClassification"]
    
                ############### Code for External sharing ########################
                $externalSharing = $false

                Write-Output "`nProcessing $newTitle"
   
      
                # Create Modern team site connected to Office 365 groups
                EnsureSite -siteEntryId $siteItem.Id -title  $newTitle -url  $newSiteUrl -namealias $nameAlias -description $description `
                    -siteCollectionAdmin $fallbackSiteCollectionAdmin `
                    -ownerAddresses $ownersEmailAddress `
                    -accesslevel $isPublic `
                    -classification $informationclassification `

            }

            if ($? -eq $true -and ($editor -ne "SharePoint App" -or $Force) -and $global:siteStatus -ne "Failed") {
                
                # Add owner / member to Owners and members Security/AD group
                
                EnsureADSecurityGroups -url $Siteurl_new  -aliasName $nameAlias -owners $ownersEmailAddress -siteEditors $siteEditorsEmailIds -isPublic $isPublic -siteStatus $global:siteStatus
                #Enable or disable external sharing - AT THIS POINT; BY DEFAULT IT IS DISABLED HERE-
                EnableOrDisableExternalSharing -url $Siteurl_new  -externalSharing $externalSharing -namealias $nameAlias

                # Disable member sharing
                # DisableMemberSharing -url $newSiteUrl

                # Set Site url in respective list item
                SetSiteUrl -siteItem $siteItem -siteUrl $Siteurl_new  -title $title

                # apply PnP Site Template
                ApplyTemplateConfigurations -url $Siteurl_new  -siteItem $siteItem -templateConfigurationItems $templateConfigurationItems -baseModuleItems $baseModuleItems -title $title -siteStatus $global:siteStatus
                # Set Site theme invoking Site theme Site design (Its pre-req.)
                Invoke-SiteDesign -url $Siteurl_new 
                # Update Site Status
                SetSiteStatusAvailable -id $siteItem.Id -status 'Available'
                # Sync Metadata
                SyncMetadata -siteItem $siteItem -siteUrl $Siteurl_new  -urlToDirectory $urlToSiteDirectory -title $title -description $description
                if ($global:siteStatus -ne 'Available') {
                    # Update Introduction text from Description in site
                    Update-SiteIntroductionText -pageName "Home" -pageText $description -url $Siteurl_new 
                    # Send Site ready email
                    SendReadyEmail -url $Siteurl_new  -toEmail $orderedByUser.Email -ccEmails $ownersEmailAddress -title $title
                }
                # Add support team AD group to site administrators
                AddUserToSiteAdmins -url $Siteurl_new  -usrName $supportGroupName
                
                # Creating teams for new site
                $createTeams = $siteItem["ALFA_CreateTeams"];
                if($createTeams -eq $true){
                    Write-Output "Creating teams for $Siteurl_new"
                    try{
                    CreateTeamsForNewSite -url $Siteurl_new
                    Write-Output "Teams created successfully."
                    }
                    catch{
                        Write-Output "Error creating teams $($_.Exception.Message)"
                    }
                }
                #Applying label
                try{
                    Disconnect-PnPOnline
                }
                catch{}
                Start-Sleep -s 120 #2 minutes delay before setting sensitivity labels
                ApplySensitivityLabel -labelTitle $siteItem["$($columnPrefix)InformationClassification"] -siteURL $Siteurl_new
                 
            }
        }
        catch {
            # Script error
            Write-Error "An error occurred: $($PSItem.ToString())"
        }
    }
    

    Disconnect-PnPOnline
}
catch {
    # Script error
    Write-Error "An error occurred: $($PSItem.ToString())"
}

#endregion