##############################################################################################################
########   This script Creates Find People Page if not present, Deploys SPFx web part and Library Extension and configures relavant web part on Find People page ######
########   Written by : Gurudatt Bhat ######
########   Pre-requisite : PnP Powershell ########
##############################################################################################################

param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]$tenantUrl,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]$environment
)

Connect-PnPOnline -Url $tenantUrl
# Make Sure you have FindPeople.pnp is in same folder from where this script is running
$path = "./" + $environment + "/FindPeople.pnp"
echo $path
Apply-PnPTenantTemplate -Path $path
Disconnect-PnPOnline