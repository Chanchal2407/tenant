#Script can run multiple time

$TopNavActionName = "ShareNavigationExtension"
$CriticalInfoActionName = "ShareCriticalInformationExtension"

$context = Get-PnPContext
$web = Get-PnPSite
$context.Load($web)
$context.Load($web.UserCustomActions)
Invoke-PnPQuery

$TopNavInstalled =$false;
$web.UserCustomActions | ForEach-Object { if ($_.Name -eq $TopNavActionName) {$TopNavInstalled=$true} }

$CriticalInfoInstalled =$false;
$web.UserCustomActions | ForEach-Object { if ($_.Name -eq $CriticalInfoActionName) {$CriticalInfoInstalled=$true} }


if (!$CriticalInfoInstalled ){
   Write-Host "Adding critical information extension..."
   $EnvironmentAppId="";
   # Select id corresponding to current environment
   switch ($Config.OrganizationSettings.environment.ToLower())
    {
        "dev"  { $EnvironmentAppId = 'e854cc73-8b1c-45f0-9a3c-2fe5168e1457' }
        "qa"   { $EnvironmentAppId = '63b3de04-5937-4a4a-80cd-96d95befa5b5' }
        "uat"  { $EnvironmentAppId = '84e650e8-59a2-4a16-aae8-4f32b9bb2e0a' }
        "prod" { $EnvironmentAppId = '0046dbdb-5661-4f63-a6da-24c6f5d75bb9' }
    }

    #Empty for prod
	$EnvironmentPostFixCriticalInfo = "";
	if ($Config.OrganizationSettings.environment.ToLower() -ne "prod" -and $Config.OrganizationSettings.environment.ToLower() -ne "dev")
	{
		$EnvironmentPostFixCriticalInfo = $Config.OrganizationSettings.environment.ToUpper();
	}
	
    $ca = $web.UserCustomActions.Add()
    $ca.Sequence = 1;
    $ca.ClientSideComponentId = $EnvironmentAppId
    $ca.ClientSideComponentProperties = "{""AlertSiteUrl"":""/sites/Share$EnvironmentPostFixCriticalInfo""}"
    $ca.Location = "ClientSideExtension.ApplicationCustomizer"
    $ca.Name = $CriticalInfoActionName 
    $ca.Title = "Critical Information Extension"
    $ca.Update()
	Invoke-PnPQuery  
}

if (!$TopNavInstalled ){

   Write-Host "Adding top navigation..."
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
}

