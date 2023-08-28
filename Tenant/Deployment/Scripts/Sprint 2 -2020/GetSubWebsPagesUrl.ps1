#PRE-REQ : PNP POWERSHELL INSTALLED IN LOCAL MACHINE
[CmdletBinding()]
param (
        [Parameter(Mandatory=$true)]
        [string]$WebUrl,
        [Parameter(Mandatory=$true)]
        [string]$TenantUrl
)

#Files.
$Files = @{
    "Report" = "C:\Users\$($env:USERNAME)\Desktop\Pages.csv";
};
 #Object array.
 $Pages = @();
Connect-PnPOnline -Url $WebUrl
$sites = Get-PnPSubWebs -Recurse 
if($null -ne $sites) {
    foreach($site in $sites){
        $serverRelativeUrl = $site.ServerRelativeUrl
        echo $TenantUrl/$serverRelativeUrl
        Connect-PnPOnline -Url $TenantUrl/$serverRelativeUrl
        Get-PnPListItem -List "Site Pages" | %{
            #Create new object.
            $Page = New-Object -TypeName PSObject;
            #Add data to the object.
            Add-Member -InputObject $Page -MemberType NoteProperty -Name Url -Value ($TenantUrl + $_.FieldValues.FileRef);
            #Add object to array.
            $Pages += $Page;
        }
        Disconnect-PnPOnline
    }
    
}

#Export to the .CSV file.
$Pages | Export-Csv -Path $Files.Report -Encoding UTF8 -Delimiter ";" -NoTypeInformation;
