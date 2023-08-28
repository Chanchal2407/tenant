##########################################################################
#Site provisioning script
#Developer: Gurudatt Bhat (Sogeti Sverige AB, Malmo Sweden)
#Description : 
#References/Inspiration: Mikhel Svenson - https://dev.office.com/blogs/provisioning-with-pnp-powershell-and-azure-webjobs
#Modified by: Karteek Saripalli
#Comments: Improved exception handling
##
##########################################################################
param(
    [switch]$Force
)

. .\shared.ps1

$templateConfigurationsList = '/Lists/Templates'
$baseModulesLibrary = 'Modules'
$timerIntervalMinutes = ([environment]::GetEnvironmentVariable("APPSETTING_TimerIntervalMinutes"))
if($timerIntervalMinutes -eq $null){
# Developer tenant      
  # $directorySiteUrl = "/sites/directoryNext"
  $timerIntervalMinutes = 30
}
# $timerIntervalMinutes = 30
$newSiteUrl = ""


#Get Unique Site Url from Site Title
function GetUniqueUrlFromName($title,$ContentType) {
    #Connect -Url $tenantAdminUrl
    Connect-AzureADAppOnly -Url $tenantAdminUrl
     #ConnectWithCredentials -Url $tenantAdminUrl -userName $userName -pw $pwPlainText
    $prefix = GetPreFixFromContentTypeName -ContentType $ContentType
    $cleanName = $title -replace '[^a-z0-9]'
    if($cleanName.length -lt 5) { 
        if($cleanName.length -eq 0) {
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
    if($cleanName.length -ge 59) {
         $cleanName = $cleanName.Substring(0,58)
    }
    if([String]::IsNullOrWhiteSpace($cleanName)){
        $cleanName = "team"
    }
    $alfaTenantUrl = $tenantAdminUrl.Replace("-admin.sharepoint",".sharepoint")
    $url = "$alfaTenantUrl/$managedPath/$cleanName"
    $doCheck = $true
	$counter = 1
    $newurl = $url
    while ($doCheck) {
        #stderr to stdout if it's error
        $newSite = Get-PnPTenantSite -Url $newurl -ErrorAction SilentlyContinue
        if($newSite -ne $null) {
            $newurl = $url + $counter
            $counter++
        } else {
            $doCheck = $false
        }
    }
    return $newurl
}

function GetPreFixFromContentTypeName($ContentType) {
    $prefix = ""
    if($ContentType -ne $null){
        if($ContentType.Name -eq "Collaboration site"){
            #Collaboration
            if($targetEnv -ne "Production") {
                 $prefix = $targetEnv + "-" + "Collaboration"
            }
            else {
                $prefix = "Collaboration"
            }
        }
        elseif($ContentType.Name -eq "Project Site"){
             #Project
            if($targetEnv -ne "Production") {
                   $prefix = $targetEnv + "-" + "Project"
            }
            else{
                $prefix = "Project"
            }
        }
    }
   return $prefix
}
function CreatePnPSite {
    Param (
        [string]$title,
        [string]$url,
        [string]$namealias,
        [string]$description = "",
        [bool]$accesslevel,
        [string]$classification
    )

    $attemptCount = 3;
    [int]$waitTime = 1;
    if ([int]::TryParse($createSiteMaxWaitingTime, [ref]$waitTime) -eq $true) {
        $attemptCount = $waitTime * 3; # 3 attempts per minute
    }
    
    # Connect
    ConnectWithCredentials -Url $tenantAdminUrl -userName $userName -pw $pwPlainText
    # Create site
    try {
        $global:Siteurl_new = New-PnPSite -Type TeamSite -Title $title -Alias $namealias -Description $description -IsPublic:$accesslevel -Classification $classification -ErrorVariable errVar -ErrorAction Stop
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
                    Write-Output "New-PnPSite: CreateGroupEx with bad status and/or invalid group id. Aborting!"
                }
                while($attemptCount -gt 0) {
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
                #throw $_
                continue;
            }
            "*The group alias already exists*" {
                Write-Output "New-PnPSite:The group alias already exists,Try with different name"
                $global:siteStatus = "Failed";
            }
            Default {
                # Rethrow and catch error in outer catch
                #throw $_
                continue;
            }
        }
    }
    # Site was created. Return site
    [console]::WriteLine("New-PnPSite: Site creation executed");
    $global:siteStatus = "Active";
    return;
}

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

    #Connect admin url
    #Connect-Graph -graphappId $graphappId -graphappSecreat $graphappSecreat -AADDomain $aadDomain
    #ConnectWithCredentials -Url $tenantAdminUrl -userName $userName -pw $pwPlainText
    Connect-AzureADAppOnly -Url $tenantAdminUrl
    $site = Get-PnPTenantSite -Url $url -ErrorAction SilentlyContinue
    if($site -eq $null) {
        Write-Output "Site at $url does not exist - let's create it"
        # Connect-MSGraphAPI
        # ConnectWithCredentials -Url $tenantAdminUrl -userName $userName -pw $pwPlainText
        # Create site
        CreatePnPSite -title $title -url $newSiteUrl -namealias $nameAlias -description $description -accesslevel $isPublic -classification $informationclassification


        #If SiteStatus is Failed, due to some error site is not created
        if($global:siteStatus -eq "Failed") {
            # send e-mail
            Connect-AzureADAppOnly -Url $tenantAdminUrl
            $mailHeadBody = GetMailContent -email $ownerAddresses -mailFile "fail"
            Write-Output "Sending fail mail to $ownerAddresses"
			$requestItemUrl = "$tenantURL$siteDirectorySiteUrl$siteDirectoryList/DispForm.aspx?ID=$siteEntryId"
            Send-PnPMail -To $ownerAddresses -Subject $mailHeadBody[0] -Body ($mailHeadBody[1] -f $requestItemUrl)
            Write-Output "Setting site status to Failed"
            UpdateStatus -id $siteEntryId -status 'Failed'
            return;
        }        
        Start-Sleep -s 60 # extra sleep before setting site col admins
    } elseif ($site.Status -ne "Active") {
        Write-Output "Site at $url already exist"
        while($true) {
            Connect-AzureADAppOnly -Url $tenantAdminUrl
            # Wait for site to be ready
            $site = Get-PnPTenantSite -Url $url
            if( $site.Status -eq "Active" ) {
                break;
            }
            Write-Output "Site not ready"
            Start-Sleep -s 20
        }
        Start-Sleep -s 60 # extra sleep before setting site col admins
    }

    #Connect -Url $tenantAdminUrl
    Connect-AzureADAppOnly -Url $tenantAdminUrl
    $site = Get-PnPTenantSite -Url $url
    if($site -ne $null){
        $global:siteStatus = "Active"
    }else{
        $global:siteStatus = "Failed"
    }
}

#This method sends Site ready email to Site requestor cc'ing Business Owner
function SendReadyEmail(){
    Param(
        [string]$url,
        [string]$toEmail,
        [String[]]$ccEmails,
        [string]$title
    )
    try{
     # http://anoojnair.com/2016/07/the-email-message-cannot-be-sent-make-sure-the-email-has-a-valid-recipient/
     # Connecting to tenant roote site endpoint
    $alfaTenantUrl = $tenantAdminUrl.Replace("-admin.sharepoint",".sharepoint")
    Connect-AzureADAppOnly -Url $alfaTenantUrl   
    if( -not [string]::IsNullOrWhiteSpace($toEmail) ) {
        $mailHeadBody = GetMailContent -email $toEmail -mailFile "welcome"
        
        Write-Output "Sending ready mail to $toEmail and $ccEmails"
        Send-PnPMail -To $toEmail -Cc $ccEmails -Subject ($mailHeadBody[0] -f $title) -Body ($mailHeadBody[1] -f $title,$url)
    }
  }
  catch{
      Write-Output "Exception sending email $($_.Exception.Message)"
  }
}

#This method applies OfficeDevPnP Provisioning template (.PnP) to newly created site, followed by non templatized solution and sets the property bag of the site request
function ApplyTemplate([string]$url, [string]$templateUrl, [string]$templateName,[string]$title) {
    Connect-AzureADAppOnly -Url $url
    # Below line of code not in use at the moment, but it is kept for future purpose as Microsoft is planning to release Key value pair entries
    # Which would work like Property bag (ETA : By 2018 year end or 2019 Q1)
    $appliedTemplates = Get-PnPPropertyBag -Key $propBagTemplateInfoStampKey
    if((-not $appliedTemplates.Contains("|$templateName|")-or $Force))  {
        Write-Output "`tApplying template $templateName to $url"
        #Check context of connectedUrl is similar to parameter, If yes, respective apply .pnp template
        $ctx = Get-PnPContext
        if($ctx.Url -eq $url){
          Apply-PnPProvisioningTemplate -Path $templateUrl
        }
    } else {
        Write-Output "`tTemplate $templateName already applied to $url"
    }
}

<#
This method gets Template information from Site request and gets actual OpenXML file from Modules
and Applies PnP Provison template to site
#>
function ApplyTemplateConfigurations($url, $siteItem, $templateConfigurationItems, $baseModuleItems,$title,$siteStatus) {
    if($siteStatus -ne 'Available') {
            #Connect -Url $url
            Connect-AzureADAppOnly -Url $url
            #ConnectWithCredentials -Url $url -userName $userName -pw $pwPlainText
            $templateConfig = $siteItem["$($columnPrefix)TemplateConfig"]
            if($templateConfig -ne $null) {
                $chosenTemplateConfig = $templateConfigurationItems |? Id -eq $templateConfig.LookupId
                if ($chosenTemplateConfig -ne $null) {
                    $chosenBaseTemplate = $chosenTemplateConfig["$($columnPrefix)ALFA_Modules"]
                    if ($chosenBaseTemplate -ne $null) {
                        $pnpTemplate = $baseModuleItems |? Id -eq $chosenBaseTemplate.LookupId
                        $alfaTenantUrl = $tenantAdminUrl.Replace("-admin.sharepoint",".sharepoint")
                        $pnpUrl = $alfaTenantUrl + $pnpTemplate["FileRef"]
                        echo $pnpUrl
                        ApplyTemplate -url $url -templateUrl $pnpUrl -templateName $pnpTemplate["FileLeafRef"] $title
                    }
                }
            }
            else {
                Write-Output "Template not found"
            }
    }
}

<#
  This method ensures AD security group and set Owners / members of the group
#>
function EnsureADSecurityGroups([string]$url,[string]$nameAlias,[string[]]$owners,[string[]]$siteEditors,[bool]$isPublic,[string]$siteStatus){
        
        # Add owners to member group
        $allMembers = ($owners + $siteEditors) | select -Unique
        
        # Get group from site
        Connect-AzureADAppOnly -Url $url
        $site = Get-PnPSite -Includes Id,GroupId
        [string]$groupSiteId = $site.GroupId
        Write-Output "Site Group Id :  $groupSiteId"

        # Update group
        if($siteStatus -ne 'Available') {
            Connect-MSGraphAPI
            if($isPublic){
                Set-PnPUnifiedGroup -Identity $groupSiteId -Owners $owners -Members $allMembers -ErrorAction SilentlyContinue >$null 2>&1
            }else{
                #Private
                Set-PnPUnifiedGroup -Identity $groupSiteId -IsPrivate -Owners $owners -Members $allMembers -ErrorAction SilentlyContinue >$null 2>&1
            }
            Write-Output "Owners and members are added successfully"
        }

        # Do not update Site Editors for already crerated sites
        #else {
        #    # This means Site is in Available status and only thing I could update is Site editors.
        #    # Permission at SharePoint level is "Members"
        #    Connect-MSGraphAPI
        #    # Note : Set-PnPUnifiedGroup removes and adds new users. In our case,we would like to keep existing users and add new user.
        #    # Get all current members , append to Site Editors variable
        #    $existingMembers = Get-PnPUnifiedGroupMembers -Identity $groupSiteId
        #    if($existingMembers.Count -ge 0){
        #        $existingMembers | %{ $siteEditors += $_.UserPrincipalName }
        #    }
        #    Set-PnPUnifiedGroup -Identity $groupSiteId -Members $siteEditors -ErrorAction SilentlyContinue >$null 2>&1
        #    Write-Output "Site members/editors are updated successfully"
        #}
}


<#
Set Group Logo (Not using it)
#>
function EnsureGroupLogo([string]$url,[string]$nameAlias,[string]$groupLogoPath){
    #ConnectWithCredentials -Url $url -userName $userName -pw $pwPlainText
    Connect-AzureADAppOnly -Url $url
    $site = Get-PnPSite -Includes Id,GroupId
    [string]$groupSiteId = $site.GroupId
    Write-Output "Site Group Id :  $groupSiteId"
    #Now connecting to App only context using Microsoft Graph.
    Connect-AzureADAppOnly -Url $url
    Set-PnPUnifiedGroup -Identity $groupSiteId -GroupLogoPath $groupLogoPath -ErrorAction SilentlyContinue >$null 2>&1
    Write-Output "Owners and members are added successfully"
}

<#
This method Ensures all security group and adds users mentioned in Site request form to respective security group
#>
function EnsureSecurityGroups([string]$url, [string]$title, [string[]]$owners, [string[]]$siteEditors, [string[]]$visitors, [string]$siteCollectionAdmin) {
    #Connect -Url $url
    Connect-AzureADAppOnly -Url $url
    #ConnectWithCredentials -Url $url -userName $userName -pw $pwPlainText
    $visitorsGroup = Get-PnPGroup -AssociatedVisitorGroup -ErrorAction SilentlyContinue
    if( $? -eq $false) {
        Write-Output "Creating visitors group"
        $visitorsGroup = New-PnPGroup -Title "$title Visitors" -Owner $siteCollectionAdmin
        Set-PnPGroup -Identity $visitorsGroup -SetAssociatedGroup Visitors
    }

    $editorsGroup = Get-PnPGroup -AssociatedMemberGroup -ErrorAction SilentlyContinue
    if( $? -eq $false) {
        Write-Output "Creating members group"
        $editorsGroup = New-PnPGroup -Title "$title Members" -Owner $siteCollectionAdmin
        Set-PnPGroup -Identity $editorsGroup -SetAssociatedGroup Members
    }

    $ownersGroup = Get-PnPGroup -AssociatedOwnerGroup -ErrorAction SilentlyContinue
    if( $? -eq $false) {
        Write-Output "Creating owners group"
        $ownersGroup = New-PnPGroup -Title "$title Owners" -Owner $siteCollectionAdmin
        Set-PnPGroup -Identity $ownersGroup -SetAssociatedGroup Owners
    }

    if($owners -ne $null) {
        Write-Output "`tAdding owners: $owners"
        foreach($login in $owners) {
            Add-PnPUserToGroup -Identity $ownersGroup -LoginName $login
        }
    }

    if($siteEditors -ne $null) {
        Write-Output "`tAdding members: $siteEditors"
        foreach($login in $siteEditors) {
            Add-PnPUserToGroup -Identity $membersGroup -LoginName $login
        }
    }

    if($visitors -ne $null) {
        Write-Output "`tAdding visitors: $visitors"
        foreach($login in $visitors) {
            Add-PnPUserToGroup -Identity $visitorsGroup -LoginName $login
        }
    }
}


function AddUserToSiteAdmins([string]$url,[string]$usrName){
    # Connect to the site
    Connect-AzureADAppOnly -Url $url
    # Split users (if multiple)
    $usrArray = $usrName.Split(',').Trim()
    # Add user/group to site admins
    Add-PnPSiteCollectionAdmin -Owners $usrArray -WarningAction SilentlyContinue -WarningVariable WarningMsg
    # Log
    if ($WarningMsg) {
        Write-Output "WARNING adding user to site administrators"
        Write-Output "Warning: $WarningMsg"
    } else {
        Write-Output "$usrName is added to site administrators successfully"
    }
}
 
<#
.SYNOPSIS
Short description

.DESCRIPTION
Long description

.PARAMETER url
Parameter description

.PARAMETER informationClassification
Parameter description

.EXAMPLE
An example

.NOTES
 This method sets Site Classification
#>
function SetSiteClassification([string]$url,[string]$informationClassification,[string]$siteStatus){
    if($siteStatus -ne 'Available'){
        # doesn't work
        # https://github.com/SharePoint/sp-dev-docs/issues/859
        #
        #Connect-AzureADAppOnly -Url $url
        #$site = Get-PnPSite -Includes Classification
        #$site.Classification = $informationClassification
        #Invoke-PnPQuery

        # workaround
        #
        Connect-MSGraphAPI
        $token = Get-PnPAccessToken
        Connect-AzureADAppOnly -Url $url
        $site = Get-PnPSite -Includes Classification
        [Microsoft.SharePoint.Client.SiteExtensions]::SetSiteClassification($site, $informationClassification, $token)

        Write-Output "Site Classification has been set to $informationClassification"
    }
}

<#
  This method invokes Site design theme
#>
function Set-ThemeSiteDesign([string]$url,[string[]]$owners){
    try{
        Invoke-SiteDesign -url $url
    }
    catch{
        # Retry once again
        Write-Output $_.Exception.Message
    }
}

<#
This method sets Site Url to list item
#>
function SetSiteUrl($siteItem, $siteUrl, $title) {
    #Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Connect-AzureADAppOnly -Url "$tenantURL$siteDirectorySiteUrl"
    Write-Output "Setting site URL to $siteUrl"
    Set-PnPListItem -List $siteDirectoryList -Identity $siteItem["ID"] -Values @{"$($columnPrefix)SiteURL" = "$siteUrl, $title"} -ErrorAction SilentlyContinue >$null 2>&1
}

#Update Site request status
function UpdateStatus($id, $status) {
    #Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Connect-AzureADAppOnly -Url "$tenantURL$siteDirectorySiteUrl"
    Set-PnPListItem -List $siteDirectoryList -Identity $id -Values @{"$($columnPrefix)SiteStatus" = $status} -ErrorAction SilentlyContinue >$null 2>&1
}

#Update/Choose Template based on Content type
function UpdateTemplateByContentType($siteItem) {
    if($siteItem["$($columnPrefix)SiteStatus"] -ne 'Available'){
            $templateLookUpNo = $null;
            $prop = Get-PnPProperty -ClientObject $siteItem -Property ContentType
            if($prop -ne $null) {
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
               $templateLookUpNo = Get-PnPListItem -List "Project Templates" -Query $correctTemplateCaml | Select Id
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
            
            Set-PnPListItem -List Sites -Identity $siteItem -Values @{"$($columnPrefix)TemplateConfig" = $templateLookUpNo.Id} -SystemUpdate
            Write-Output "Updated the Template of list item successfully"
    }
}

#Get/return Recently updated/newly created new item from Site Request list
function GetRecentlyUpdatedItems($IntervalMinutes) {
    Connect -Url "$tenantURL$siteDirectorySiteUrl"
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
            <Neq>
                <FieldRef Name='ALFA_SiteStatus' />
                <Value Type='Choice'>Failed</Value>
            </Neq>
          </And>
        </Where>
        <OrderBy>
            <FieldRef Name="Modified" Ascending="False" />
        </OrderBy>
    </Query>
    <ViewFields>
        <FieldRef Name="ID" />
        <FieldRef Name="ALFA_SiteStatus" />
    </ViewFields>
</View>
"@
    if($Force){
        return @(Get-PnPListItem -List $siteDirectoryList)    
    }else {
        return @(Get-PnPListItem -List $siteDirectoryList -Query $recentlyUpdatedCaml)
    }    
}

Write-Output @"
  AlfaLaval Site Provisioning engine starts here.
"@

$tenantURL = $tenantURL + $directorySiteUrl
#ConnectWithCredentials -Url "$tenantURL$siteDirectorySiteUrl" -userName $userName -pw $pwPlainText
Connect-AzureADAppOnly -Url "$tenantURL$siteDirectorySiteUrl"
echo "$tenantURL$siteDirectorySiteUrl"
$templateConfigurationItems = @(Get-PnPListItem -List $templateConfigurationsList)
$baseModuleItems = @(Get-PnPListItem -List $baseModulesLibrary)
$siteDirectoryItems = GetRecentlyUpdatedItems -Interval $timerIntervalMinutes

if(!$siteDirectoryItems -or ($siteDirectoryItems -ne $null -and (0 -eq $siteDirectoryItems.Count))) {
    Write-Output "No site requests detected last $timerIntervalMinutes minutes"
}

#Iterate through all Requested sites list and Update Respective template based on selected Content type
foreach ($siteItem in $siteDirectoryItems) {
 #Below method updates Template of the request based on Content type
   UpdateTemplateByContentType($siteItem)
}

#Iterate through all Requested sites list and create site now
foreach ($siteItem in $siteDirectoryItems) {
    Connect-AzureADAppOnly -Url "$tenantURL$siteDirectorySiteUrl"
    #Get initial editor - which is needed for checks further down
    $siteItem = Get-PnPListItem -List $siteDirectoryList -Id $siteItem.ID
    if($siteItem -ne $null -and $siteItem -ne "") {

    # get title
    $title = $siteItem["Title"]

    if( $siteItem["$($columnPrefix)SiteURL"] -eq $null) {
        $prop = Get-PnPProperty -ClientObject $siteItem -Property ContentType
        #$siteUrl = GetUniqueUrlFromName -title $title -ContentType $prop
        $newSiteUrl = GetUniqueUrlFromName -title $title -ContentType $prop
        $nameAlias = $newSiteUrl.Substring($newSiteUrl.LastIndexOf("/") + 1)
    } else {
        #$siteUrl = $siteItem["$($columnPrefix)SiteURL"].Url
        $newSiteUrl = $siteItem["$($columnPrefix)SiteURL"].Url
        $nameAlias =  $newSiteUrl.Substring($newSiteUrl.LastIndexOf("/") + 1)

        # Skip edited item processing
        Write-Output "$nameAlias skiped because not new site request"
        continue
    }

    $editor = $siteItem["Editor"][0].LookUpValue 

    #$siteItem = Get-PnPListItem -List $siteDirectoryList -Id $siteItem.ID #load all fields

    $orderedByUser = $siteItem["Author"][0]
       
    $description = $siteItem["$($columnPrefix)ProjectDescription"]
    #$ownerEmailAddresses = @(@($siteItem["$($columnPrefix)SiteOwners"]) |? {-not [String]::IsNullOrEmpty($_.Email)} | select -ExpandProperty Email)
    $global:siteStatus = $siteItem["$($columnPrefix)SiteStatus"]

    $owners = @($siteItem["$($columnPrefix)SiteOwners"]) | select -ExpandProperty LookupId
    $owners = @($owners |% { GetLoginName -lookupId $_ }) 
    $ownersUPNs = @($owners |% { GetUserUPN -loginName $_ })
    $ownersUPNs += $userName;

    $ownersEmailAddress = @($siteItem["$($columnPrefix)SiteOwners"] |? {-not [String]::IsNullOrEmpty($_.Email)} | select -ExpandProperty Email)
    # Combine UPN strin array and email address and get unique values. By doing this we will not miss any accounts to get added to 
    # owners group
    ###---$ownersEmailAddress = $ownersEmailIds + $ownersEmailAddress
    ###---$ownersEmailAddress += $userName;
    ###---$ownersEmailAddress = $ownersEmailAddress | select -Unique

    #Editors
    $siteEditors = @($siteItem["$($columnPrefix)SiteEditor"]) | select -ExpandProperty LookupId
    $siteEditors = @($siteEditors |% { GetLoginName -lookupId $_ })
    ###---$siteEditorsEmailIds = @($siteEditors |% { GetUserEmail -loginName $_ })
    $siteEditorsUPNs = @($siteEditors |% { GetUserUPN -loginName $_ }) 
    ###---$siteEditorsEmailIds = $siteEditorsEmailIds + $siteEditorsUPNs | select -Unique
    $siteEditorsEmailIds = @($siteItem["$($columnPrefix)SiteEditor"] |? {-not [String]::IsNullOrEmpty($_.Email)} | select -ExpandProperty Email)
        
    ############ Code for Setting Access level #####################
    $isPublic = $false
    $acesslevel = $siteItem["$($columnPrefix)AccessLevel"]
    #TODO: Handle it in better way
    if($acesslevel -eq "Private"){
        $isPublic = $false
    }
    else{
        $isPublic = $true
    }

    ############ Code for Setting Information classification level #####################
   $informationclassification = $siteItem["$($columnPrefix)InformationClassification"]
    
   ############### Code for External sharing ########################
   $externalSharing = $false

    Write-Output "`nProcessing $newSiteUrl"
    #Connect -Url "$tenantURL$siteDirectorySiteUrl"
    Connect-AzureADAppOnly -Url "$tenantURL$siteDirectorySiteUrl"
    #$urlToSiteDirectory = "$tenantURL$siteDirectorySiteUrl$siteDirectoryList"
      
    # Create Modern team site connected to Office 365 groups
    EnsureSite -siteEntryId $siteItem["ID"] -title $title -url $newSiteUrl -namealias $nameAlias -description $description `
        -siteCollectionAdmin $fallbackSiteCollectionAdmin `
        -ownerAddresses $ownersEmailAddress `
        -accesslevel $isPublic `
        -classification $informationclassification `


    if ($? -eq $true -and ($editor -ne "SharePoint App" -or $Force) -and $global:siteStatus -ne "Failed") {
                # Add owner / member
                EnsureADSecurityGroups -url $newSiteUrl -aliasName $nameAlias -owners $ownersUPNs -siteEditors $siteEditorsUPNs -isPublic $isPublic -siteStatus $global:siteStatus
                # Set Request access email - removed according to UserStory 4951: Update Access request settings to point to  "Collboration site Admin" by default, when Collaboration site is created
                #SetRequestAccessEmail -url $newSiteUrl -ownersEmail ($ownersEmailAddress -join ',') -siteStatus $siteStatus
                # Disable / Enable External sharing based on request
                EnableOrDisableExternalSharing -url $newSiteUrl -externalSharing $externalSharing -namealias $nameAlias
                 # Disable member sharing
                DisableMemberSharing -url $newSiteUrl
                # Set Site url in respective list item
                SetSiteUrl -siteItem $siteItem -siteUrl $newSiteUrl -title $title
                ApplyTemplateConfigurations -url $newSiteUrl -siteItem $siteItem -templateConfigurationItems $templateConfigurationItems -baseModuleItems $baseModuleItems -title $title -siteStatus $global:siteStatus
                # Set Site theme invoking Site theme Site design (Its pre-req.)
                Set-ThemeSiteDesign -url $newSiteUrl -owners $ownersEmailAddress 
                UpdateStatus -id $siteItem["ID"] -status 'Available'
                SyncMetadata -siteItem $siteItem -siteUrl $newSiteUrl -urlToDirectory $urlToSiteDirectory -title $title -description $description
                if($global:siteStatus -ne 'Available'){
                    Update-SiteIntroductionText -pageName "Home" -pageText $description -url $newSiteUrl
                    SendReadyEmail -url $newSiteUrl -toEmail $orderedByUser.Email -ccEmails $ownersEmailAddress -title $title
                }
                # Set site classification
                SetSiteClassification -url $newSiteUrl -informationClassification $informationclassification -siteStatus $global:siteStatus
                # Add support group to site administrators
                if ($supportGroupName -ne "") {
                    AddUserToSiteAdmins -url $newSiteUrl -usrName $supportGroupName
                }
      }
    }
}

Disconnect-PnPOnline