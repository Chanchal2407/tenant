# This script reads Brp Group login name from csv file and add those groups to respective site visitors group
# Written By : Gurudatt Bhat

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$csvPath,
    [Parameter(Mandatory=$true)]
    $siteUrl
)
$Global:logs = @()
$BRPGroups = Import-Csv $csvPath

#Generating the Logs 
Function GenerateLogs([String]$logType, [String]$groupName, [String]$loginName, [String]$errorMessage, [String]$lineNumber, [String]$scriptLineNumber, [String]$exceptionItemName, [String]$methodName){
    $row = New-Object PSObject
    $row | Add-Member -MemberType NoteProperty -Name "Log Type" -Value $logType
    $row | Add-Member -MemberType NoteProperty -Name "Group Name" -Value $groupName
    $row | Add-Member -MemberType NoteProperty -Name "Login Name" -Value $loginName
    $row | Add-Member -MemberType NoteProperty -Name "Message" -Value $errorMessage 
    $row | Add-Member -MemberType NoteProperty -Name "Error in Line" -Value $lineNumber
    $row | Add-Member -MemberType NoteProperty -Name "Error in Line Number" -Value $scriptLineNumber 
    $row | Add-Member -MemberType NoteProperty -Name "Error Item Name" -Value $exceptionItemName 
    $row | Add-Member -MemberType NoteProperty -Name "MethodName" -Value $methodName 
    $Global:logs += $row 
}

# Connect to Site
Connect-PnPOnline -Url $siteUrl
$visitorsGroup = Get-PnPGroup -AssociatedVisitorGroup
if( $null -ne $BRPGroups ) {
    foreach($group in $BRPGroups){
        Try{
            #Add-PnPUserToGroup method deprecated
            #Add-PnPUserToGroup -Identity $visitorsGroup.Title -LoginName $group.BRPGroupLoginName
            Add-PnPGroupMember -Identity $visitorsGroup.Title -LoginName $group.BRPGroupLoginName
            Write-Output "Added BRP Group $($group.BRPTitle) sucessfully"
            GenerateLogs "Success" $group.BRPTitle $group.BRPGroupLoginName "Group Added Successfully" "" "" "" "Adding Group"
          }Catch{
            Write-Host ("Error Message: {0}" -f $_.Exception.Message)
            <#Write-Host ("Error in Line: {0}" -f $_.InvocationInfo.Line)
            Write-Host ("Error in Line Number: {0}" -f $_.InvocationInfo.ScriptLineNumber)
            Write-Host ("Error Item Name: {0}" -f $_.Exception.ItemName)#>
            GenerateLogs "Error" $group.BRPTitle $group.BRPGroupLoginName $_.Exception.Message $_.InvocationInfo.Line $_.InvocationInfo.ScriptLineNumber $_.Exception.ItemName "Adding Group"
        }
    }
}

$currentTime= $(get-date).ToString("yyyyMMddHHmmss")
$outputFilePath=".\Logs-AddingBRPGroup-"+$currentTime+".csv"
$Global:logs | Export-Csv $outputFilePath -NoTypeInformation
Disconnect-PnPOnline