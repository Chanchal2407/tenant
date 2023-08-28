$userEmail = Import-csv -Path "C:\temp\Book2.csv" -Delimiter ","

Connect-PnPOnline -Url "https://alfalavalonline.sharepoint.com" -UseWebLogin

if($null -ne $userEmail) {

    $userEmail | %{
       
       $userIdentity = "i:0#.f|membership|" + $_.Email.ToLower();

       $user = Get-PnPUser -Identity $userIdentity -ErrorAction SilentlyContinue
       if($null -eq $user) {
           echo "Check user email id"
           echo $_.Email
       }
    }

}

Disconnect-PnPOnline