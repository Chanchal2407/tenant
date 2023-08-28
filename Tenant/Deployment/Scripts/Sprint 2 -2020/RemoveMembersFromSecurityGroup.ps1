#PRE-REQ : PNP POWERSHELL INSTALLED IN LOCAL MACHINE
[CmdletBinding()]
param (
        [Parameter(Mandatory=$true)]
        [string]$WebUrl,
        [Parameter(Mandatory=$true)]
        [string]$SecurityGroupName,
        [Parameter(Mandatory=$true)]
        [string]$CSVPath
)
  
Connect-PnPOnline -Url $WebUrl
$usersCsv = Import-Csv $CSVPath -Delimiter ";"
if($null -ne $usersCsv) {
 foreach ( $user in $usersCsv) {
   try{
     echo $user.Email
     Remove-PnPUserFromGroup -LoginName $user.Email -Identity $SecurityGroupName
     echo "Removed $user.Email successfully"
   } 
   catch{
       echo $user.Email " Not found"
   }
 }
}
