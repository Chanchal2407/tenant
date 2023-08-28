#####################################################################################
#Written By : Gurudatt Bhat
#Purpose : This script fetches all users from Azure AD using Microsoft graph along with Open Extension property extension_48c7727299ef46c983ddc8a6cdb02f50_employeeType to 
#          identify whether AD account is real user or Group/Service account and creats a .txt file which could be easiky be converted as .csv/-xlsx file

#####################################################################################
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$AppId,
    [Parameter(Mandatory=$true)]
    [string]$AppSecret,
    [Parameter(Mandatory=$true)]
    [string]$TenantId
)


# $client_secret =  | ConvertTo-SecureString
$client_secret  = ConvertTo-SecureString -String $AppSecret -AsPlainText -Force
$app_cred = New-Object System.Management.Automation.PsCredential($AppId, $client_secret)
$TenantId = $TenantId

$body = @{
    client_id     = $AppId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $app_cred.GetNetworkCredential().Password
    grant_type    = "client_credentials"
}
 
try { $tokenRequest = Invoke-WebRequest -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing -ErrorAction Stop }
catch { Write-Host "Unable to obtain access token, aborting..."; return }

$token = ($tokenRequest.Content | ConvertFrom-Json).access_token

#$token = "eyJ0eXAiOiJKV1QiLCJub25jZSI6IkN3dkRkWGF3dFc4ZTFQc3FvQVV2dUJZeG9fLWJMcVZaMjVzdWJjUzJlN1UiLCJhbGciOiJSUzI1NiIsIng1dCI6ImppYk5ia0ZTU2JteFBZck45Q0ZxUms0SzRndyIsImtpZCI6ImppYk5ia0ZTU2JteFBZck45Q0ZxUms0SzRndyJ9.eyJhdWQiOiIwMDAwMDAwMy0wMDAwLTAwMDAtYzAwMC0wMDAwMDAwMDAwMDAiLCJpc3MiOiJodHRwczovL3N0cy53aW5kb3dzLm5ldC9lZDVkNWY0Ny01MmRkLTQ4YWYtOTBjYS1mN2JkODM2MjRlYjkvIiwiaWF0IjoxNTk5MDQyMzQzLCJuYmYiOjE1OTkwNDIzNDMsImV4cCI6MTU5OTA0NjI0MywiYWNjdCI6MCwiYWNyIjoiMSIsImFpbyI6IkFVUUF1LzhRQUFBQXk1bGl5bGZkTDBWWVhHbld6eldGRk0rM0N4TDlFUFdodEIwWGJWMDRGSnBqdmM0MHJiczhPSVFnZXNEMWZjayt5dElTNzdGR0VzNEdXMjNwWDNtR25RPT0iLCJhbXIiOlsicHdkIiwibWZhIl0sImFwcF9kaXNwbGF5bmFtZSI6IkdyYXBoIGV4cGxvcmVyIChvZmZpY2lhbCBzaXRlKSIsImFwcGlkIjoiZGU4YmM4YjUtZDlmOS00OGIxLWE4YWQtYjc0OGRhNzI1MDY0IiwiYXBwaWRhY3IiOiIwIiwiZmFtaWx5X25hbWUiOiJCaGF0IChhZG1pbikiLCJnaXZlbl9uYW1lIjoiR3VydWRhdHQiLCJpZHR5cCI6InVzZXIiLCJpcGFkZHIiOiIyMTIuMzkuMzIuMTA4IiwibmFtZSI6Ikd1cnVkYXR0IEJoYXQgKGFkbWluKSIsIm9pZCI6ImIzM2ZjZDBkLWIyOGEtNDIzNC1iYmE4LTQ3ZWJlZmU3MWFlMSIsInBsYXRmIjoiMyIsInB1aWQiOiIxMDAzMjAwMDcyMEU5NDRDIiwicmgiOiIwLkFRd0FSMTlkN2QxU3IwaVF5dmU5ZzJKT3ViWElpOTc1MmJGSXFLMjNTTnB5VUdRTUFKOC4iLCJzY3AiOiJBdWRpdExvZy5SZWFkLkFsbCBDYWxlbmRhcnMuUmVhZFdyaXRlIENvbnRhY3RzLlJlYWRXcml0ZSBEaXJlY3RvcnkuUmVhZC5BbGwgRmlsZXMuUmVhZFdyaXRlLkFsbCBHcm91cC5SZWFkV3JpdGUuQWxsIE1haWwuUmVhZFdyaXRlIE1haWxib3hTZXR0aW5ncy5SZWFkV3JpdGUgTm90ZXMuUmVhZFdyaXRlLkFsbCBvcGVuaWQgUGVvcGxlLlJlYWQgcHJvZmlsZSBTZWN1cml0eUV2ZW50cy5SZWFkLkFsbCBTaXRlcy5SZWFkV3JpdGUuQWxsIFRhc2tzLlJlYWRXcml0ZSBVc2VyLlJlYWQgVXNlci5SZWFkLkFsbCBVc2VyLlJlYWRCYXNpYy5BbGwgVXNlci5SZWFkV3JpdGUgVXNlckFjdGl2aXR5LlJlYWRXcml0ZS5DcmVhdGVkQnlBcHAgZW1haWwiLCJzaWduaW5fc3RhdGUiOlsiaW5rbm93bm50d2siXSwic3ViIjoiTF9yZjZxSTJ1RmpRSGJDQ1dFclg1RmIyZVBhWHpOTUVJWWJGODZJRE9qOCIsInRlbmFudF9yZWdpb25fc2NvcGUiOiJFVSIsInRpZCI6ImVkNWQ1ZjQ3LTUyZGQtNDhhZi05MGNhLWY3YmQ4MzYyNGViOSIsInVuaXF1ZV9uYW1lIjoiZ3VydWRhdHQuYmhhdEBhbGZhbGF2YWxvbmxpbmUub25taWNyb3NvZnQuY29tIiwidXBuIjoiZ3VydWRhdHQuYmhhdEBhbGZhbGF2YWxvbmxpbmUub25taWNyb3NvZnQuY29tIiwidXRpIjoiM3ExaXVrVjRpMGFGSVE2NEprd1JBQSIsInZlciI6IjEuMCIsIndpZHMiOlsiNjkwOTEyNDYtMjBlOC00YTU2LWFhNGQtMDY2MDc1YjJhN2E4IiwiMTE2NDg1OTctOTI2Yy00Y2YzLTljMzYtYmNlYmIwYmE4ZGNjIiwiOWI4OTVkOTItMmNkMy00NGM3LTlkMDItYTZhYzJkNWVhNWMzIiwiMDk2NGJiNWUtOWJkYi00ZDdiLWFjMjktNThlNzk0ODYyYTQwIiwiZjJlZjk5MmMtM2FmYi00NmI5LWI3Y2YtYTEyNmVlNzRjNDUxIiwiZjI4YTFmNTAtZjZlNy00NTcxLTgxOGItNmExMmYyYWY2YjZjIl0sInhtc19zdCI6eyJzdWIiOiJNOTlpNm9PX1hQSS1RbVh1TzFhTEVMNXMwelNjQnlCSGdKYmJnOU1jdnFNIn0sInhtc190Y2R0IjoxNDAwNDg2Njk4fQ.UeUdXZQaV9VsJXqmLFI4dYBYOjr1f2HYiQi8Xzl2YiC9liqVNQSfeBGXqH7ADXXZSojfxyScLdYOM4jsWAaPfOATKfNJu5bn13UOidnSGw7ysFF_7lTEdtqHO7cYHe7CBGSA9c_Ey8P0hBDuVXrzdn_nqmhElTOz9tf9tLFq0VJxFyB2FGSzuX9zeVR1bnyAT11jm-UCZ3utzCoaM7xXBAb0E7T4KCDacnBBzNDljXBIZ98IOLBFlFrq26NHSfGcgRDxoL08QuZUyG7grkuhsa3zjNSGKeHikPSrF8TAxcWHD10yinJzlOA6pt3ISxWuyHEw-9FHGPE-nUphIErKqQ"

$authHeader1 = @{
   'Content-Type'='application\json'
   'Authorization'="Bearer $token"
}

#Get all user accounts from Azure AD users (Except External Users)
#$graphApi = 'https://graph.microsoft.com/v1.0/users?$select=userPrincipalName,extension_48c7727299ef46c983ddc8a6cdb02f50_employeeType'
$allUserAccounts = Invoke-WebRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/users?$select=Id,userPrincipalName,extension_48c7727299ef46c983ddc8a6cdb02f50_employeeType' -Headers $authHeader1 | ConvertFrom-Json

$allUserAccounts.Value.ForEach( {
    $userDetails = ""
    #Double check to make sure External users are not preset
    if(-not ($_.userPrincipalName -like "*#EXT#*")) {    
    $userDetails += $_.Id + "," + $_.userPrincipalName + "," + $_.extension_48c7727299ef46c983ddc8a6cdb02f50_employeeType
    $userDetails | Out-File "ALUsersWithAccountType.txt" -Append
            }
        }
    )

$NextLink = $allUserAccounts.'@Odata.NextLink'
echo $NextLink
While ( $NextLink -ne $Null ) {
    $allUserAccounts = Invoke-WebRequest -Method GET -Uri $NextLink -Headers $authHeader1 | ConvertFrom-Json
    Start-Sleep -Milliseconds 500
    $allUserAccounts.Value.ForEach( {
        $userDetails = ""
        if(-not ($_.userPrincipalName -like "*#EXT#*")) {
        $userDetails += $_.Id + "," + $_.userPrincipalName + "," + $_.extension_48c7727299ef46c983ddc8a6cdb02f50_employeeType
        $userDetails | Out-File "ALUsersWithAccountType.txt" -Append
    } } )
   $NextLink = $allUserAccounts.'@odata.NextLink'
}

