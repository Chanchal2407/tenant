# Configuration
$TopNavActionName = "ShareNavigationExtension"
$SiteUrl = $($Config.organizationsettings.tenantUrl + $Config.SiteCollections.RootSite.SiteUrl) 

# Connect
Connect-PnPOnline -Url $SiteUrl -Credentials $O365Credential -ErrorAction Stop

$context = Get-PnPContext
$web = Get-PnPSite
$context.Load($web)
$context.Load($web.UserCustomActions)
Invoke-PnPQuery

$TopNavInstalled =$false;
$web.UserCustomActions | ForEach-Object { if ($_.Name -eq $TopNavActionName) {$TopNavInstalled = $true} }

if (!$TopNavInstalled ) {

   Write-Host "Adding top navigation... " -NoNewline
   $EnvironmentAppId="";
   # Select id corresponding to current environment
   switch ($Config.OrganizationSettings.environment.ToLower())
    {
        "dev"  { $EnvironmentAppId = '3a1c4835-459b-45c7-9665-17c7f50ec181' }
        "qa"   { $EnvironmentAppId = 'a7494c80-0681-4e03-bdb2-29a38122105e' }
        "uat"  { $EnvironmentAppId = 'e6e03d86-5104-49e8-8f1d-8bb471343e77' }
        "prod" { $EnvironmentAppId = '1fd0ff15-3c75-4da4-8e4f-f4ab92adece3' }
    }
    
    #Empty for prod
	$EnvironmentPostFix = "";
	if ($Config.OrganizationSettings.environment.ToLower() -ne "prod")
	{
		$environmentPostFix = "-"+$Config.OrganizationSettings.environment.ToLower();
	}

    $ca = $web.UserCustomActions.Add()
    $ca.Sequence = 2;
    $ca.ClientSideComponentId = $EnvironmentAppId
    $ca.ClientSideComponentProperties = "{""TopMenuTermSet"":""Top Navigation$environmentPostFix""}"
    $ca.Location = "ClientSideExtension.ApplicationCustomizer"
    $ca.Name = $TopNavActionName 
    $ca.Title = "Share Navigation Extension"
    $ca.Description = "Custom action for Tenant Global NavBar Application Customizer"
    $ca.Update()
    Invoke-PnPQuery
    Write-Host "OK"
}

# Disconnect
Disconnect-PnPOnline