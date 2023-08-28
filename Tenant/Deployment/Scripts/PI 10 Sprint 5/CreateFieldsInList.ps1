# This script will create Fields in mentioned List by reading csv fields list
param (
	[Parameter(Mandatory=$true)][string]$Url,
    [Parameter(Mandatory=$true)][string]$ListName
 )

cls
$fields = Import-Csv -Path Fields.csv
if( $null -ne $fields) {
    Connect-PnPOnline -Url $Url
    $fields | %{
        try {
            
            Add-PnPField  -List $ListName -InternalName $_.InternalName -DisplayName $_.DisplayName -Type $_.Type -AddToDefaultView
            echo "$($_.DisplayName) created successfully"
        }
        catch{
            echo $_.Exception.Message
        }
    
    }
    Disconnect-PnPOnline
}