##########################################################################
#Site provisioning script
#Developer: Gurudatt Bhat (Sogeti Sverige AB, Malmo Sweden)
#Description : This script file contains Helper methods for Site provisioning
#References/Inspiration: Mikhel Svenson - https://dev.office.com/blogs/provisioning-with-pnp-powershell-and-azure-webjobs
##
##
##########################################################################

############################################################################>
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
echo $PSScriptRoot
Add-Type -Path $PSScriptRoot\bundle\Microsoft.SharePoint.Client.dll -ErrorAction SilentlyContinue
Add-Type -Path $PSScriptRoot\bundle\Microsoft.SharePoint.Client.Taxonomy.dll -ErrorAction SilentlyContinue
Add-Type -Path $PSScriptRoot\bundle\Microsoft.SharePoint.Client.DocumentManagement.dll -ErrorAction SilentlyContinue
Add-Type -Path $PSScriptRoot\bundle\Microsoft.SharePoint.Client.WorkflowServices.dll -ErrorAction SilentlyContinue
Add-Type -Path $PSScriptRoot\bundle\Microsoft.SharePoint.Client.Search.dll -ErrorAction SilentlyContinue
Add-Type -Path $PSScriptRoot\bundle\OfficeDevPnP.Core.dll -ErrorAction SilentlyContinue

Add-Type -Path $PSScriptRoot\bundle\Newtonsoft.Json.dll -ErrorAction SilentlyContinue
Import-Module $PSScriptRoot\bundle\SharePointPnPPowerShellOnline.psd1 -ErrorAction SilentlyContinue

Set-PnPTraceLog -Off

$tenantURL = ([environment]::GetEnvironmentVariable("APPSETTING_TenantURL"))
echo $tenantURL
if($tenantURL -eq $null){
    # Developer tenant
    $tenantURL = "https://sogeti10.sharepoint.com"
}

$directorySiteUrl = ([environment]::GetEnvironmentVariable("APPSETTING_DirectorySiteUrl"))
echo $directorySiteUrl
if($directorySiteUrl -eq $null){
   #Developer tenant      
   $directorySiteUrl = "/sites/directoryNext"
}

$fallbackSiteCollectionAdmin = ([environment]::GetEnvironmentVariable("APPSETTING_PrimarySiteCollectionOwnerEmail"))
echo $fallbackSiteCollectionAdmin
if($fallbackSiteCollectionAdmin  -eq $null){
    $fallbackSiteCollectionAdmin = "gurudattbn@sogeti10.onmicrosoft.com"
}

$siteDirectorySiteUrl = ([environment]::GetEnvironmentVariable("APPSETTING_SiteDirectoryUrl"))
echo $siteDirectorySiteUrl
if($siteDirectorySiteUrl -eq $null){
    #Collaboration site url
    $siteDirectorySiteUrl = "/collaboration"
}

#Azure appsettings variables - remove prefix when adding in azure
$appId = ([environment]::GetEnvironmentVariable("APPSETTING_AppId"))
echo $appId
if($appId -eq $null){
   # $appId = ([environment]::GetEnvironmentVariable("APPSETTING_ClientId"))
   #Dev AppId
   echo "App Id App settings not present"
   #Dev App id
   $appId = "93ca3e73-68e2-4145-b696-7876bd8dec27";
   #UAT App id
   #$appId = "8217a02d-605b-4bb0-9a7a-866cc14dd2ae";
   #Alfalaval UAT App id
   #$appId = "ad1a97cf-acbc-48c0-a55f-b69d7f4226b2";
}

$appSecret = ([environment]::GetEnvironmentVariable("APPSETTING_AppSecret"))
if($appSecret -eq $null){
    echo "App Secreat App settings not present"
    #Dev App secreat
    echo $appSecret
    $appSecret = "I54/dProQC6xacnwBIgLNInUert1AI0phO4j9lIFp4w=";
    #$appSecret = "iSgBVp+knZ1Yqd8T/fpje/X92rH5BNQN72opd8BDRaI=";
    #$appSecret = "9f0ow5sXk9soMmq7aeNheTCie+qToDeMupNZeHgRM78=";
}

$graphappId = ([environment]::GetEnvironmentVariable("APPSETTING_GraphAppId"))
echo "Graph Id $graphappId"
if($graphappId -eq $null){
   $graphappId = "93ca3e73-68e2-4145-b696-7876bd8dec27"
  # $graphappId = "8217a02d-605b-4bb0-9a7a-866cc14dd2ae"
   #$graphappId = "ad1a97cf-acbc-48c0-a55f-b69d7f4226b2"
}

$certiName = ([environment]::GetEnvironmentVariable("APPSETTING_pfxName"))
echo "Certificate name : $certiName"
if($certiName -eq $null){
    #$certiName = "AlfalavalCollaborationOnline.pfx"
    #$certiName = "AlfaCollab.pfx"
    $certiName = "AlfalavalProvisioning.pfx"
}

$certificatePassword = ([environment]::GetEnvironmentVariable("APPSETTING_pfxPassword"))
if($certificatePassword -eq "" -or $certificatePassword -eq $null){
    $certiPassword = ConvertTo-SecureString -AsPlainText "1qaz!QAZ" -Force
}
else{
    $certiPassword = ConvertTo-SecureString -AsPlainText $certificatePassword -Force
}

$aadDomain = ([environment]::GetEnvironmentVariable("APPSETTING_AADomain"))
echo "AADDomain $aadDomain"
if($aadDomain -eq $null){
    $aadDomain  = "****"
   # $aadDomain  = "alfalavalonline.onmicrosoft.com"
    #$aadDomain  = "alfademos.onmicrosoft.com"
}

#Site design id
$siteDesignId = ([environment]::GetEnvironmentVariable("APPSETTING_SiteDesignId"))
echo  "Site Design id : $siteDesignId" 
if($siteDesignId -eq $null){
    $siteDesignId  = "e9da985c-0eb2-4cc9-a0c3-deaf64f9fc72"
    #$siteDesignId  = "842bc727-3999-42a7-9ece-74d76e9c9e4a"
    #$siteDesignId = "f02ecd00-3515-48b1-b07d-33d885b0e45b"
}

$uri = [Uri]$tenantURL
$tenantUrl = $uri.Scheme + "://" + $uri.Host
$tenantAdminUrl = $tenantUrl.Replace(".sharepoint", "-admin.sharepoint")
#TODO: Remove username and password, use alternative (Microsoft Graph API)
#Update: Invoke-PnPsiteDesin  using Azure AD Graph API has issues at the time of writing this. Till that we could use only Username and passord
#More details could be followed here
#https://github.com/SharePoint/PnP-PowerShell/issues/1492
#Update (16/05/2018) : It is now possible to invoke Site design by connecting to admin endpoint first within PnP Powershell

$userName = ([environment]::GetEnvironmentVariable("APPSETTING_serviceAccountName"))
echo "Username $userName"
if ($userName -eq $null){
    $userName = "****"
}

$pwPlainText = ([environment]::GetEnvironmentVariable("APPSETTING_serviceAccountpassword"))
if ($pwPlainText -eq $null){
    $pwPlainText = "****"  
}

$targetEnv =  ([environment]::GetEnvironmentVariable("APPSETTING_TargetEnvironment"))
echo "Target environment $targetEnv"
if($targetEnv -eq $null) {
    $targetEnv = "DEV"
    #$targetEnv = "Production"
}

$supportGroupName =  ([environment]::GetEnvironmentVariable("APPSETTING_SupportGroupName"))
echo "Support group name: $supportGroupName"
if($supportGroupName -eq $null) {
    $supportGroupName = ""
}

$createSiteMaxWaitingTime =  ([environment]::GetEnvironmentVariable("APPSETTING_createSiteMaxWaitingTime"))
echo "New site max waiting time: $createSiteMaxWaitingTime"
if($createSiteMaxWaitingTime -eq $null) {
    $createSiteMaxWaitingTime = "1"
}

$siteDirectoryList = '/Lists/Sites'
$propertybagAlternativeList = 'PropertyBagAlternatives'
#$managedPath = 'teams' # sites/teams - Since LoB Sites, Its "sites"
$managedPath = 'sites'
$columnPrefix = 'ALFA_'
$propBagTemplateInfoStampKey = "_PnP_CollaborationAppliedTemplateInfo"
$propBagMetadataStampKey = "ProjectMetadata"

$Global:lastContextUrl = ''

# TODO: In modern team site, there is no property bag support. There is a way to workaround it, 
# Rather we will use SharePoint list and hide the list from end user
$siteMetadataToPersist = @([pscustomobject]@{DisplayName = "-SiteDirectory_SiteEditors-"; InternalName = "$($columnPrefix)SiteEditor"},
    [pscustomobject]@{DisplayName = "-SiteDirectory_SiteOwners-"; InternalName = "$($columnPrefix)SiteOwners"}
    [pscustomobject]@{DisplayName = "-SiteDirectory_Organization-"; InternalName = "$($columnPrefix)Organization"}
    [pscustomobject]@{DisplayName = "-SiteDirectory_InformationClassification-"; InternalName = "$($columnPrefix)InformationClassification"}
    [pscustomobject]@{DisplayName = "-SiteDirectory_ProjectManager-"; InternalName = "Project_x0020_Manager"}
    [pscustomobject]@{DisplayName = "-SiteDirectory_Template-"; InternalName = "$($columnPrefix)TemplateConfig"}
)

<#
Connects to SharePoint site using App Id and App Secreat (SharePoint App only context)
#>
function Connect([string]$Url){    
    if($Url -eq $Global:lastContextUrl){
        return
    }
    if ($appId -ne $null -and $appSecret -ne $null) {
        Write-Output "Connecting to $Url using AppId $appId" 
        Connect-PnPOnline -Url $Url -AppId $appId -AppSecret $appSecret
    } else {
        #Write-Output "AppId or AppSecret not defined, try connecting using stored credentials" -ForegroundColor Yellow
        Connect-PnPOnline -Url $Url 
    }
    $Global:lastContextUrl = $Url
}

<#
Connects to SharePoint site using username and password
Scopes are set to ReadWrite
#>
function ConnectWithCredentials([string]$Url,[string]$userName,[string]$pw){  
   #if($Url -eq $Global:lastContextUrl){
      #  return
   # }
    echo "Inside ConnectWithCredentials"
    if ($userName -ne $null -and $pw -ne $null) {       
        #Write-Output "Connecting to $Url using AppId $appId" 
        $securePassword = ConvertTo-SecureString -AsPlainText $pw -Force
         # Get the credentials
         
        $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName,$securePassword  
        Connect-PnPOnline -Url $Url -Credentials $credentials
    } else {
        #Write-Output "AppId or AppSecret not defined, try connecting using stored credentials" -ForegroundColor Yellow
        Connect-PnPOnline -Url $Url
    }
    $Global:lastContextUrl = $Url
}

<#
Connects with SPO commandlets
#>
function ConnectSPOWithCredentials([string]$Url){    
    if($Url -eq $Global:lastContextUrl){
        return
    }
    if ($userName -ne $null -and $pwPlainText -ne $null) {
        #Write-Output "Connecting to $Url using AppId $appId" 
        $securePassword = ConvertTo-SecureString -AsPlainText $pwPlainText -Force
         # Get the credentials  
        $credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName,$securePassword  
        Connect-SPOService -Url $Url -Credential $credentials
    } else {
        #Write-Output "AppId or AppSecret not defined, try connecting using stored credentials" -ForegroundColor Yellow
        Connect-SPOService -Url $Url
    }
    $Global:lastContextUrl = $Url
}

<#
Connect to SharePoint Online using Microsoft graph api endpoint
#>
function Connect-Graph([string]$graphappId,[string]$graphappSecreat,[string]$AADDomain){
    #Connect-PnPOnline -App
    if($graphappId -ne $null -and $graphappSecreat -ne $null -and $AADDomain -ne $null){
        Connect-PnPOnline -AppId $graphappId -AppSecret $graphappSecreat -AADDomain $AADDomain
    }
    $Global:lastContextUrl = "";
}

<#
Connect to SharePoint Online using Azure AD Authentication
#>
function Connect-AzureADAppOnly([string]$Url){
    #Connect-PnPOnline -App
    if($Url -ne $null){
       <# if($Url -eq $Global:lastContextUrl){
            return
        }#>
        $certificatePath = $PSScriptRoot + "\certificate\$certiName"
        Connect-PnPOnline -Url $Url -ClientId $graphappId -CertificatePath $certificatePath -CertificatePassword $certiPassword -Tenant $AADDomain
    }
    $Global:lastContextUrl = $Url;
}

<#
Connect to SharePoint Online using Microsoft graph api endpoint
#>
function Connect-MSGraphAPI(){
    Write-Output "Calling Graph API endpoint"
    Write-Output "client secreat : $appSecret"
    Connect-PnPOnline -AppId $graphappId -AppSecret $appSecret -AADDomain $aadDomain
}

<#
Return mail stream based on specific mail file
#>
function GetMailContent{
    Param(
        [string]$email,
        [string]$mailFile
    )
    $ext = "en";
    if($mail) {
        $ext = $email.Substring($email.LastIndexOf(".")+1)
    }
    $filename = "$PSScriptRoot/resources/$mailFile-mail-$ext.txt"
    if(-not (Test-Path $filename)) {
        $ext = "en"
        $filename = "$PSScriptRoot/resources/$mailFile-mail-$ext.txt"
    }
    return ([IO.File]::ReadAllText($filename)).Split("|")
}

<#
Get Login Name
#>
function GetLoginName{
    Param(
        [int]$lookupId
    )
    #Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Connect-AzureADAppOnly -Url "$tenantURL$siteDirectorySiteUrl"
    $web = Get-PnPWeb
    $user = Get-PnPListItem -List $web.SiteUserInfoList -Id $lookupId
    return $user["Name"]    
}

<#
Get User Email
#>
function GetUserEmail{
    Param(
        [string]$loginName
    )
 #   Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Connect-AzureADAppOnly -Url "$tenantURL$siteDirectorySiteUrl"
    $user =  Get-PnPUser -Identity $loginName
    return $user.Email
}

<#
Get User UPN (UserPrincipalName)
There is no direct method,so getting UPN value by string operation
#>
function GetUserUPN{
    Param(
        [string]$loginName
    )
    $upnName = ""
 #   Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Connect-AzureADAppOnly -Url "$tenantURL$siteDirectorySiteUrl"
    $user =  Get-PnPUser -Identity $loginName
    if($user -ne $null){
        $upnName = $user.LoginName.Substring($user.LoginName.LastIndexOf('|') + 1 )
    }
    return $upnName
}

<#
Sets Request Access mail  with Site Owner email address
#>
function SetRequestAccessEmail([string]$url, [string]$ownersEmail,[string]$siteStatus) {
    if($siteStatus -ne 'Available'){
        if( [String]::IsNullOrEmpty($ownersEmail)) {
            Write-Output "`tUnable to set site request e-mail because there are no Site owners"
        } else {
        # Connect -Url $url
            Connect-AzureADAppOnly -Url $url
            #ConnectWithCredentials -Url $url -userName $userName -pw $pwPlainText
            $emails = Get-PnPRequestAccessEmails
            if($emails -ne $ownersEmail) {
                Write-Output "`tSetting site request e-mail to $ownersEmail"    
                Set-PnPRequestAccessEmails -Emails $ownersEmail
            }
        }
    }
}

<#
Disable the members of the site to share data externally
#>
function DisableMemberSharing([string]$url){
    #Connect -Url $url
    Connect-AzureADAppOnly -Url $url
    #ConnectWithCredentials -Url $url -userName $userName -pw $pwPlainText
    $web = Get-PnPWeb
    $canShare = Get-PnPProperty -ClientObject $web -Property MembersCanShare
    if($canShare) {
        Write-Output "`tDisabling members from sharing"
        $web.MembersCanShare = $false
        $web.Update()
        $web.Context.ExecuteQuery() 
    }
}

#Enables or disables the External sharing Policy of Modern team site (aka Office 365 groups)
function EnableOrDisableExternalSharing([string]$url,[bool]$externalSharing,[string]$namealias){
    if($externalSharing){
        Connect-AzureADAppOnly -Url $tenantAdminUrl
        Set-PnPTenantSite -Url $url -Sharing ExternalUserSharingOnly
        echo "Extnernal sharing has been enabled successfully"
    }
    else{
        # Check Current sharing capability, If Disabled, dont do anything, If enabled, Disable it.
        # Note : By default, external sharing is enabled in office 365 group related site collection
        # Note : External sharing opton is changed over the period to True to False, all existing external users will still remain. Thats OOTB.
        Connect-AzureADAppOnly -Url $tenantAdminUrl
        $site = Get-PnPTenantSite -Url $url -Detailed
        if($site.SharingCapability -ne "Disabled"){
            Set-PnPTenantSite -Url $url -Sharing Disabled -NoScriptSite:$true
            echo "Extnernal Sharing and Site Scripts has been disabled successfully"

            #$DenyAddAndCustomizePagesStatusEnum = [Microsoft.Online.SharePoint.TenantAdministration.DenyAddAndCustomizePagesStatus]
            #$site.DenyAddAndCustomizePages = $DenyAddAndCustomizePagesStatusEnum::Disabled
            #$site.Update()
            #Invoke-PnPQuery
            #echo "Site scripts have been disabled successfully"

            Disable-External-Sharing -url $url -namealias $namealias
            echo "Guest inviting disabled at Outlook online level successfully"
        }
        else{
            #TODO: Enable guest access. Commented as 
            #Disable-External-Sharing -url $url -namealias $namealias
            echo "Guest inviting enabled at Outlook online level successfully"
        }
    }
}


#FOR FUTURE USE
function CheckSitePolicy{
    Param(
        [string]$url
    )
 #   Connect -Url $url
    Connect-AzureADAppOnly -Url $url
    #ConnectWithCredentials -Url $url -userName $userName -pw $pwPlainText
    $policyName = "Delete unconfirmed after 3 months"
    $policy = Get-PnPSitePolicy
    if($policy -eq $null -or $policy.Name -ne $policyName) {
        Write-Output "`tApplying site policy: $policyName"
        Set-PnPSitePolicy -Name $policyName
    }
}

<#
This creates Key Value Metadata property $propBag
#>
function CreateKeyValueMetadataObject($key, $fieldType, $fieldValue, $fieldInternalName) {
    $value = @{
        'Type' = $fieldType
        'Data' = $fieldValue
        'FieldName' = $fieldInternalName
    }
    $properties = @{
        'Key' = $key
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
        if($fieldValue -ne $null) {
            $valueType = $fieldValue.GetType().Name
            $valueData = $fieldValue.ToString()
            if ($valueType -eq "FieldUserValue") {
                $valueData = "$($fieldValue.LookupId)|$($fieldValue.LookupValue)|$($fieldValue.Email)"
            } elseif ($valueType -eq "FieldUserValue[]") {
                $valueData = @($fieldValue |% {"$($_.LookupId)|$($_.LookupValue)|$($_.Email)"}) -join "#"
            } elseif ($valueType -eq "FieldUrlValue") {
                $valueData = $fieldValue.Url + "," + $fieldValue.Description
            } elseif ($valueType -eq "FieldLookupValue") {
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

<#
This method Sync changed/updated metadata from Site request form to respetive site
#>
function SyncMetadata($siteItem, $siteUrl, $urlToDirectory, $title, $description) {
    $itemId =  $siteItem.Id
    $editFormUrl = "$urlToDirectory/EditForm.aspx?ID=$itemId" + "&Source=$siteUrl/SitePages/Home.aspx"

    $metadataJson = CreateMetadataPropertyValue -siteItem $siteItem -editFormUrl $editFormUrl -siteMetadataToPersist $siteMetadataToPersist

    #Connect -Url $siteUrl
    Connect-AzureADAppOnly -Url $siteUrl
    Write-Output "`tPersisting project metadata to $siteUrl - $metadataJson"
    $listItem = Get-PnPListItem -List $propertybagAlternativeList -Id 1 -ErrorAction SilentlyContinue

     $strOwners=New-Object System.Collections.ArrayList;
     $strEditors=New-Object System.Collections.ArrayList;

    if($listItem -eq $null) {
       
        Add-PnPListItem -List $propertybagAlternativeList -Values @{"Title"=$propBagMetadataStampKey;"PropertyBagValuesJSON"=$metadataJson}

       #siteOwner
       $siteOwners = @($siteItem["$($columnPrefix)SiteOwners"]) | Select-Object Email,LookupValue

       foreach ($User in $siteOwners) {
           $strOwners.Add(($User.LookupValue + "|" + $User.Email));
       }

            if($strOwners.Count -gt 0){
                $mainOwner  = @($strOwners)[0];
            }
            else{
                $mainOwner  = "";
            }
        
       Add-PnPListItem -List $propertybagAlternativeList -Values @{"Title"="SiteOwner";"PropertyBagValuesJSON"=$mainOwner}

       #siteEditor
       $siteEditors = @($siteItem["$($columnPrefix)SiteEditor"]) | Select-Object Email,LookupValue

       foreach ($User in $siteEditors) {
           $strEditors.Add(($User.LookupValue + "|" + $User.Email));
       }

        if($strEditors.Count -gt 0){
            $mainEditor  = @($strEditors)[0];
        }
        else{
            $mainEditor  = "";
        }
       Add-PnPListItem -List $propertybagAlternativeList -Values @{"Title"="SiteEditor";"PropertyBagValuesJSON"=$mainEditor}
    }

    if($title -ne $null -and $description -ne $null) {
        Set-PnPWeb -Title $title -Description $description
    }

}
#Sync permissions
function SyncPermissions{
    Param(
        [string]$url
    )

    Write-Output "`tSyncing owners/members/visitors from site to directory list"
    #Connect -Url $url
    Connect-AzureADAppOnly -Url $siteUrl
    #ConnectWithCredentials -Url $url -userName $userName -pw $pwPlainText
    $visitorsGroup = Get-PnPGroup -AssociatedVisitorGroup -ErrorAction SilentlyContinue
    $membersGroup = Get-PnPGroup -AssociatedMemberGroup -ErrorAction SilentlyContinue
    $ownersGroup = Get-PnPGroup -AssociatedOwnerGroup -ErrorAction SilentlyContinue

    $visitors = @($visitorsGroup.Users | select -ExpandProperty LoginName)
    $members = @($membersGroup.Users | select -ExpandProperty LoginName)
    $owners = @($ownersGroup.Users | select -ExpandProperty LoginName)

    $metadata = Get-PnPPropertyBag -Key ProjectMetadata | ConvertFrom-Json
    $itemId = [Regex]::Match( ($metadata |? Key -eq '-SiteDirectory_ShowProjectInformation-').Value.Data, 'ID=(?<ID>\d+)').Groups["ID"].Value
    
    #Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Connect-AzureADAppOnly -Url "$tenantURL$siteDirectorySiteUrl"
    #ConnectWithCredentials -Url "$tenantURL$siteDirectorySiteUrl" -userName $userName -pw $pwPlainText
    $owners = @($owners -notlike 'SHAREPOINT\system' |% {New-PnPUser -LoginName $_ | select -ExpandProperty ID} | sort) 
    $members = @($members -notlike 'SHAREPOINT\system' |% {New-PnPUser -LoginName $_ | select -ExpandProperty ID} | sort) 
    $visitors = @($visitors -notlike 'SHAREPOINT\system' |% {New-PnPUser -LoginName $_ | select -ExpandProperty ID} | sort) 

    $existingSiteItem = Get-PnPListItem -List $siteDirectoryList -Id $itemId
    $existingOwners = @($existingSiteItem["$($columnPrefix)SiteOwners"] | select -ExpandProperty LookupId | sort)
    $existingMembers = @($existingSiteItem["$($columnPrefix)SiteMembers"] | select -ExpandProperty LookupId | sort)
    $existingVisitors = @($existingSiteItem["$($columnPrefix)SiteVisitors"] | select -ExpandProperty LookupId | sort)

    $diffOwner = Compare-Object -ReferenceObject $owners -DifferenceObject $existingOwners -PassThru
    $diffMember = Compare-Object -ReferenceObject $members -DifferenceObject $existingMembers -PassThru
    $diffVisitor = Compare-Object -ReferenceObject $visitors -DifferenceObject $existingVisitors -PassThru

    if($diffOwner -or $diffMember -or $diffVisitor) {
        $siteItem = Set-PnPListItem -List $siteDirectoryList -Identity $itemId -Values @{"$($columnPrefix)SiteOwners" = $owners; "$($columnPrefix)SiteMembers" = $members; "$($columnPrefix)SiteVisitors" = $visitors}

        $urlToSiteDirectory = "$tenantURL$siteDirectorySiteUrl$siteDirectoryList"
       # SyncMetadata -siteItem $siteItem -siteUrl $url -urlToDirectory $urlToSiteDirectory
    }
}


#This method adds modern page to Site pages. Page would be empty during site creation
#Note, This code is written before PnP Powershell added cmdlets to create modern page. You could change it to use PnP Powershell
#cmdlet as well..
function Add-ModernPage{
    param(
        [string]$pageName,
        [string]$url
    )
    #Connect -Url $url
    Connect-AzureADAppOnly -Url $url
    #ConnectWithCredentials -Url $url -userName $userName -pw $pwPlainText
    $webContext = Get-PnPContext
    [OfficeDevPnP.Core.Pages.ClientSidePage]$clientsidePage = New-Object OfficeDevPnP.Core.Pages.ClientSidePage($webContext)
    $clientsidePage.Save($pageName);
}

#Method written with and after September 2017 update
function Add-NewModernPage{
     param(
        [string]$pageName
    )
    #Adding modern Home page and promoting as Home page
    Add-PnPClientSidePage -Name $pageName  -LayoutType Home
}

#Adds Introduction text to site from provided site description
function Update-SiteIntroductionText{
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
   $webparts = Get-PnPClientSideComponent -Page $pageName
   $webparts |ForEach-Object {
       if($_.GetType().Name -eq "ClientSideText" -and $_.Section.Order -eq 1){
         $webpartInstanceId = $_.InstanceId
       }
   }
    if($webpartInstanceId -ne $null){
        Set-PnPClientSideText -Page $pageName -InstanceId $webpartInstanceId -Text $pageText
        Write-Output "Page Introduction is updated successfully"
    }
  
}

# TODO: Replace credentials with ADAL Authentication
# Problem earlier and solution is explained in https://github.com/SharePoint/PnP-PowerShell/issues/1492
#
function Invoke-SiteDesign([string]$url) {
 if($url -ne $null) {

     # Tenant admin endpoint , to apply theme is behaving inconsistently, so switched back to Credential based Theme.
     ConnectWithCredentials -Url $url -userName $userName -pw $pwPlainText
     # Connect to Admin endpoint
     # Connect-AzureADAppOnly -Url $tenantAdminUrl
     Invoke-PnPSiteDesign -Identity $siteDesignId -WebUrl $url
     Write-Output "Site design to apply themes applied successfully"
     
 }
}

# Disable external sharing in Outlook online
# By default Office 365 group is public by default (at least when writing this code)., eventhough External sharing is disabled
# at Office 365 group explicitly ( SharingCapability = Disabled ), through Outlook online its possible to invite external users
# since project requirement is not no external sharing by default, we are explicitly disabling Guest invite in Outlook online.
# Note: Graph Api needs Directory.ReadWrite.All privilegde to perform this action.
function Disable-External-Sharing([string]$url,[string]$namealias) {
   #TODO: Yet to write
   if($url -ne $null -and $namealias -ne $null) {
         Connect-MSGraphAPI
         #get group by id
         $group = Get-PnPUnifiedGroup -Identity $namealias
         #Get the access token
         $token = Get-PnPAccessToken
         #Prepare headers
         $headers = @{"Content-Type" = "application/json" ; "Authorization" = "Bearer " + $token}
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