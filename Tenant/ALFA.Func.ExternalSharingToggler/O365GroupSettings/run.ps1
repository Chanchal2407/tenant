# POST method: $req
$requestBody = Get-Content $req -Raw | ConvertFrom-Json
echo $requestBody
echo "Referer : " $req_headers_Referer
$refVal = $req_headers_Referer
#$name = $requestBody.name
$siteUrl = $requestBody.siteUrl
$isExternalSharingON = $requestBody.isExternalSharingON
# GET method: each querystring parameter is its own variable
if ($req_query_name) 
{
    $name = $req_query_name 
}

# Disable external sharing in SharePoint site
function DisableEnableSiteExternalSharing([string]$url,[bool]$isSharing) {
  try {
    $uri = [Uri]$siteUrl
    $tenantUrl = $uri.Scheme + "://" + $uri.Host
    $tenantAdminUrl = $tenantUrl.Replace(".sharepoint", "-admin.sharepoint")
    Connect-PnPOnline -ClientId $appId -Tenant $tenant -PEMCertificate $pemCertificate -PEMPrivateKey $pemKey -Url $tenantAdminUrl
    if($isSharing) {
      Set-PnPTenantSite -Url $url -Sharing ExternalUserSharingOnly
      echo "Sharing enabled"
    }
    else {
      Set-PnPTenantSite -Url $url -Sharing Disabled
      echo "Sharing disabled"
    }
  } catch{
    echo $_.Exception.Message
  }
}

# Disable external sharing in Outlook online (Office 365 Groups level)
# By default Office 365 group is public by default (at least when writing this code)., eventhough External sharing is disabled
# at Office 365 group explicitly ( SharingCapability = Disabled ), through Outlook online its possible to invite external users
# since project requirement is not no external sharing by default, we are explicitly disabling Guest invite in Outlook online.
# Note: Graph Api needs Directory.ReadWrite.All privilegde to perform this action.
function DisableEnableGroupsExternalSharing([string]$url,[string]$nameAlias,[bool]$isSharing) {
  try {
   #TODO: Yet to write
   if($url -ne $null -and $nameAlias -ne $null) {
            echo $appId
            echo $appsecreat
            echo $url
            $uri = [Uri]$siteUrl
           # $tenantUrl = $uri.Scheme + "://" + $uri.Host

          #Connect-PnPOnline -Url $tenantUrl -Credentials $psCredentials
          #Make connection
          Connect-PnPOnline -AppId $appId -AppSecret $appsecreat -AADDomain $tenant
         #get group
         $group = Get-PnPUnifiedGroup -Identity $nameAlias
         #Get the access token
         $token = Get-PnPAccessToken
         #Prepare headers
         $headers = @{"Content-Type" = "application/json" ; "Authorization" = "Bearer " + $token}
         if(!$isSharing) {
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
         }
         else{
              $templateDeny = @"
         {
           "templateId": "08d542b9-071f-4e16-94b0-74abb372e3d9",
           "values": [
             {
               "name": "AllowToAddGuests",
               "value": "True"
             }
           ]
         }
"@
         }

        #Check if group settings present
        $getUrl = "https://graph.microsoft.com/v1.0/groups/$($group.GroupId)/settings/"
        $getRes = Invoke-WebRequest -Method GET -Uri $getUrl -Headers $headers -UseBasicParsing
        if($null -ne $getRes) {
          $jsonObj = ConvertFrom-Json $([String]::new($getRes.Content))
          echo $jsonObj
          if(![string]::IsNullOrEmpty($jsonObj.value.id)) {
          $settingId = $jsonObj.value.id
          echo $settingId
           #Graph URL to add settings to the group
          $url = "https://graph.microsoft.com/v1.0/groups/$($group.GroupId)/settings/$($settingId)"
          echo $url
        #Apply the template, and wait for a 204
         Invoke-WebRequest -Method PATCH -Uri $url -Headers $headers -Body $templateDeny -UseBasicParsing
         echo "Successfully set External Sharing : $($isSharing)"
          }
          else {
            # IF GROUP settings is equal to null
             #Graph URL to add settings to the group
              $url = "https://graph.microsoft.com/v1.0/groups/$($group.GroupId)/settings"
              echo $url
              #Apply the template, and wait for a 204
              Invoke-WebRequest -Method Post -Uri $url -Headers $headers -Body $templateDeny -UseBasicParsing
              echo "Successfully set External Sharing first time : $($isSharing)"
          }
        }
      
   }
  }
  catch {
    echo $_.Exception.Message
  }
}

# App Id
$appId = $env:APPSETTING_APPID
# App Secreat
$appsecreat = $env:APPSETTING_APPSECREAT
#Tenant
$tenant = $env:APPSETTING_TENANT

#PEMCertificate
$pemCertificate = $env:APPSETTING_PEMCertificate
#PEMKey
$pemKey = $env:APPSETTING_PEMKey
#Prepare tenant admin url based on url received
#$uri = [Uri]$siteUrl
#$tenantUrl = $uri.Scheme + "://" + $uri.Host
#$tenantAdminUrl = $tenantUrl.Replace(".sharepoint", "-admin.sharepoint")
#name alias
$nameAlias = $siteUrl.Substring($siteUrl.LastIndexOf("/") + 1)
echo "Calling Function"
echo $appId
echo $appsecreat
echo $url
echo $pemCertificate
echo $pemKey
#echo $tenant

if($null -ne $refVal) {
  echo "Referrer not null"
  $ruri = [Uri]$refVal
  $refererUrl = $ruri.Scheme + "://" + $ruri.Host
echo "Referrer Url : " $refererUrl
  $suri = [Uri]$siteUrl
  $stenantUrl = $suri.Scheme + "://" + $suri.Host
  echo "Tenant Url : " $stenantUrl

  if($refererUrl -eq $stenantUrl) {
    echo "Valid Referer"
    #Disable / Enable SharePoint site (part of Office 365 Groups) external sharing (Disabled/ExternalUserSharingOnly)
    DisableEnableSiteExternalSharing $siteUrl $isExternalSharingON
    
    #Disable / Enable Office 365 Groups external sharing using Microsoft Graph api
    DisableEnableGroupsExternalSharing $siteUrl $nameAlias $isExternalSharingON
    Out-File -Encoding Ascii -FilePath $res -inputObject "Hello  $siteUrl , External Sharing : $isExternalSharingON"
    }
    else {
      echo "Function app is being called from different place than where it is intended, So not changing anything"
      Out-File -Encoding Ascii -FilePath $res -inputObject "Hello  $siteUrl , External Sharing Action not taken place. Verify the source"
    }

}
else{
  echo "Function app is being called from different place than where it is intended, So not changing anything"
  Out-File -Encoding Ascii -FilePath $res -inputObject "Hello  $siteUrl , External Sharing Action not taken place. Verify the source"
}

