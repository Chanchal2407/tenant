[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]$InstrumentationKey,
    [Parameter(Mandatory=$true)]
    $AppCatalogUrl,
    [Parameter(Mandatory=$true)]
    $TenantAdminUrl,
    [Parameter(Mandatory=$true)]
    $Environment
)

# Connect to Admin site
Connect-SPOService -Url $TenantAdminUrl
$TenantPropertyKeyName = "SampleTenantProperty";
# Identify the key
switch ( $Environment )
{
    'DEV' { $TenantPropertyKeyName = 'ShareStartPageWebparts_InstrumentationKey'    }
    'QA' { $TenantPropertyKeyName = 'ShareStartPageWebpartsQA_InstrumentationKey'    }
    'UAT' { $TenantPropertyKeyName = 'ShareStartPageWebpartsUAT_InstrumentationKey'   }
    'PROD' { $TenantPropertyKeyName = 'ShareStartPageWebparts_InstrumentationKey' }
}

#Check if Tenant property present, if not, Create One.
$BRPWebpartInstrumentationKey = Get-SPOStorageEntity -Site $AppCatalogUrl -Key $TenantPropertyKeyName
if($null -eq $BRPWebpartInstrumentationKey.Value) {
    Set-SPOStorageEntity -Site $AppCatalogUrl -Key $TenantPropertyKeyName -Value $InstrumentationKey -Comments "App insights Key for Share First Page web parts" -Description "App insights Key for Share First Page web parts"
    Write-Host "App insights Key for Share Start page web parts is stored in Tenant Properties"
}
else {
    Write-Host "App insights Key for Share Start page web parts are already present in Tenant Properties"
}

Disconnect-SPOService
