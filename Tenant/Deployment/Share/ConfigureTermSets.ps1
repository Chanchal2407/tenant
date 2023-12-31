# Term set creation can be unstable. Re-run it if exceptions occur. Note that the issue regarding instability could be related to the PnP commands used.
# They perform lots of actions behind the scenes and could contribute to failures. If script tends not to work, can try to re-create it by using standard SharePoint CSOM for term management.

#Postfix for specific environemnt. Empty for prod
$EnvironmentPostFix = "";
if ($Config.OrganizationSettings.environment.ToLower() -ne "prod") {$environmentPostFix = "-"+$Config.OrganizationSettings.environment.ToLower();}

Write-Host "Checking Term groups/sets.."
$TermGroup = Get-PnPTermGroup "Share" -ErrorAction SilentlyContinue
if ($TermGroup -eq $null) {$TermGroup = New-PnPTermGroup -Name "Share" -Id "e7fc4e20-8584-4f54-be31-744860abcf6d" -ErrorAction Stop}

# Checking only against Category - assuming if it exists, then all terms are set up
if ((Get-PnPTermSet -Identity "Categories" -TermGroup $TermGroup -ErrorAction SilentlyContinue) -eq $null)
{
	# Reconnecting
	Disconnect-PnPOnline -ErrorAction Stop
	Start-Sleep -seconds 5
	Connect-PnPOnline -Url $Config.organizationsettings.sharePointAdminUrl -Credentials $O365Credential -ErrorAction Stop
	Start-Sleep -seconds 5
	Write-Host "Creating Term sets.."
	$TermGroup = Get-PnPTermGroup "Share" -ErrorAction Stop

	$CatSet = New-PnPTermSet -Name "Categories" -TermGroup $TermGroup -ErrorAction Stop -Id "a04735e8-4973-4469-a8c8-5e6fa81594ac" -Lcid 1033
	$LocSet = New-PnPTermSet -Name "Locations" -TermGroup $TermGroup -ErrorAction Stop -Id "039fc1a5-7f07-40fe-87d8-5685169d16f0" -Lcid 1033
	$OrgSet = New-PnPTermSet -Name "Organizations" -TermGroup $TermGroup -ErrorAction Stop -Id "3fe02a12-17b0-4ff8-88e0-b407eadc6fdd" -Lcid 1033
	$Chan = New-PnPTermSet -Name "Channels" -TermGroup $TermGroup -ErrorAction Stop -Id "39f04728-d576-4a10-bf58-6bee422f92ff" -Lcid 1033

	# Reconnecting
	Disconnect-PnPOnline -ErrorAction Stop
	Start-Sleep -seconds 5
	Connect-PnPOnline -Url $Config.organizationsettings.sharePointAdminUrl -Credentials $O365Credential -ErrorAction Stop
	Start-Sleep -seconds 5
	$TermGroup = Get-PnPTermGroup "Share" -ErrorAction Stop
	$CatSet = Get-PnPTermSet -Identity "a04735e8-4973-4469-a8c8-5e6fa81594ac" -TermGroup $TermGroup -ErrorAction Stop
	$LocSet = Get-PnPTermSet -Identity "039fc1a5-7f07-40fe-87d8-5685169d16f0" -TermGroup $TermGroup -ErrorAction Stop
	$OrgSet = Get-PnPTermSet -Identity "3fe02a12-17b0-4ff8-88e0-b407eadc6fdd" -TermGroup $TermGroup -ErrorAction Stop
	$Chan = Get-PnPTermSet -Identity "39f04728-d576-4a10-bf58-6bee422f92ff" -TermGroup $TermGroup -ErrorAction Stop

	$Cat = New-PnPTerm -Name "Categories" -TermSet $CatSet -TermGroup $TermGroup -ErrorAction Stop -Id "2a44badc-8612-4184-b23a-3da0b774939d" -Lcid 1033
	$Loc = New-PnPTerm -Name "Locations" -TermSet $LocSet -TermGroup $TermGroup -ErrorAction Stop -Id "23a62b61-e110-4eff-8ba1-d0c39f16e48d" -Lcid 1033
	$Org = New-PnPTerm -Name "Organizations" -TermSet $OrgSet -TermGroup $TermGroup -ErrorAction Stop -Id "e9c88a9b-8cb2-48ee-8a6a-6c289b4549aa" -Lcid 1033

	# Reconnecting
	Disconnect-PnPOnline -ErrorAction Stop
	Start-Sleep -seconds 5
	Connect-PnPOnline -Url $Config.organizationsettings.sharePointAdminUrl -Credentials $O365Credential -ErrorAction Stop
	Start-Sleep -seconds 5
	$TermGroup = Get-PnPTermGroup "Share" -ErrorAction Stop
	$Chan = Get-PnPTermSet -Identity "39f04728-d576-4a10-bf58-6bee422f92ff" -TermGroup $TermGroup -ErrorAction Stop
	$CatSet = Get-PnPTermSet -Identity "a04735e8-4973-4469-a8c8-5e6fa81594ac" -TermGroup $TermGroup -ErrorAction Stop
	$LocSet = Get-PnPTermSet -Identity "039fc1a5-7f07-40fe-87d8-5685169d16f0" -TermGroup $TermGroup -ErrorAction Stop
	$OrgSet = Get-PnPTermSet -Identity "3fe02a12-17b0-4ff8-88e0-b407eadc6fdd" -TermGroup $TermGroup -ErrorAction Stop
	$Cat = Get-PnPTerm -Id "2a44badc-8612-4184-b23a-3da0b774939d" -TermSet $CatSet -TermGroup $TermGroup -ErrorAction Stop
	$Loc = Get-PnPTerm -Id "23a62b61-e110-4eff-8ba1-d0c39f16e48d" -TermSet $LocSet -TermGroup $TermGroup -ErrorAction Stop
	$Org = Get-PnPTerm -Id "e9c88a9b-8cb2-48ee-8a6a-6c289b4549aa" -TermSet $OrgSet -TermGroup $TermGroup -ErrorAction Stop

	$Cat.IsAvailableForTagging=$false
	$Loc.IsAvailableForTagging=$false
	$Org.IsAvailableForTagging=$false
	$TermGroup.Context.ExecuteQuery()

	# Reconnecting
	Disconnect-PnPOnline -ErrorAction Stop
	Start-Sleep -seconds 5
	Connect-PnPOnline -Url $Config.organizationsettings.sharePointAdminUrl -Credentials $O365Credential -ErrorAction Stop
	Start-Sleep -seconds 5
	$TermGroup = Get-PnPTermGroup "Share" -ErrorAction Stop
	$Chan = Get-PnPTermSet -Identity "39f04728-d576-4a10-bf58-6bee422f92ff" -TermGroup $TermGroup -ErrorAction Stop
	$CatSet = Get-PnPTermSet -Identity "a04735e8-4973-4469-a8c8-5e6fa81594ac" -TermGroup $TermGroup -ErrorAction Stop
	$LocSet = Get-PnPTermSet -Identity "039fc1a5-7f07-40fe-87d8-5685169d16f0" -TermGroup $TermGroup -ErrorAction Stop
	$OrgSet = Get-PnPTermSet -Identity "3fe02a12-17b0-4ff8-88e0-b407eadc6fdd" -TermGroup $TermGroup -ErrorAction Stop
	$Cat = Get-PnPTerm -Id "2a44badc-8612-4184-b23a-3da0b774939d" -TermSet $CatSet -TermGroup $TermGroup -ErrorAction Stop
	$Loc = Get-PnPTerm -Id "23a62b61-e110-4eff-8ba1-d0c39f16e48d" -TermSet $LocSet -TermGroup $TermGroup -ErrorAction Stop
	$Org = Get-PnPTerm -Id "e9c88a9b-8cb2-48ee-8a6a-6c289b4549aa" -TermSet $OrgSet -TermGroup $TermGroup -ErrorAction Stop

	$Pin1=$Chan.ReuseTermWithPinning($Cat); $Pin1.IsAvailableForTagging=$false;
	$Pin2=$Chan.ReuseTermWithPinning($Loc); $Pin2.IsAvailableForTagging=$false;
	$Pin3=$Chan.ReuseTermWithPinning($Org); $Pin3.IsAvailableForTagging=$false;
	$TermGroup.Context.ExecuteQuery()
}

# Checking only against Top Navigation - assuming if it exists, then all terms are set up
if ((Get-PnPTermSet -Identity "Top Navigation$EnvironmentPostFix" -TermGroup $TermGroup -ErrorAction SilentlyContinue) -eq $null)
{
	Write-Host "Creating Top Navigation$EnvironmentPostFix set.."
	
	$TopNav = New-PnPTermSet -Name "Top Navigation$EnvironmentPostFix" -TermGroup $TermGroup -ErrorAction Stop -Lcid 1033
	#Setting Checkbox 'Use this Term Set for Site Navigation'
	#FYI. All Property names related to MM Nav
	#http://sharepointsimply.com/application-development/configure-term-store-settings-for-navigation-and-term-driven-pages-using-powershell/
	$TopNav.SetCustomProperty("_Sys_Nav_IsNavigationTermSet", "True");
	$TopNav.Context.ExecuteQuery();

	#Add default navigation nodes
	Write-Host "Adding default labels for Top Navigation.."
	New-PnPTerm -Name "Home" -TermSet $TopNav -TermGroup $TermGroup -Lcid 1033 -LocalCustomProperties @{ HighlightingExpression = "https:\/\/(.*)\.sharepoint\.com\/sites\/Share(UAT|QA|EV|)(\/SitePages\/Home\.aspx|''|\/|)$" } 
	New-PnPTerm -Name "News Portal" -TermSet $TopNav -TermGroup $TermGroup -Lcid 1033 -LocalCustomProperties @{ HighlightingExpression = "^https:\/\/(.*)\.sharepoint\.com\/sites\/Share(UAT|QA|DEV|)/SitePages/NewsPortal.aspx" }
	New-PnPTerm -Name "Products, Service & Industries" -TermSet $TopNav -TermGroup $TermGroup -Lcid 1033 -LocalCustomProperties @{ HighlightingExpression = "^https:\/\/(.*)\.sharepoint\.com\/sites\/Share(UAT|QA|DEV|)/productsandservices/" }
	New-PnPTerm -Name "About Me" -TermSet $TopNav -TermGroup $TermGroup -Lcid 1033 -LocalCustomProperties @{ HighlightingExpression = "^https:\/\/(.*)\.sharepoint\.com\/sites\/Share(UAT|QA|DEV|)/aboutme/" }
	New-PnPTerm -Name "Find People" -TermSet $TopNav -TermGroup $TermGroup -Lcid 1033 -LocalCustomProperties @{ HighlightingExpression = "^https:\/\/(.*)\.sharepoint\.com\/sites\/Share(UAT|QA|DEV|)/people/" }
	New-PnPTerm -Name "Collaboration" -TermSet $TopNav -TermGroup $TermGroup -Lcid 1033 -LocalCustomProperties @{ HighlightingExpression = "^https:\/\/(.*)\.sharepoint\.com\/sites\/collaborationlanding(dev|qa|uat|)|^https:\/\/(.*)\.sharepoint\.com\/sites\/(.*)(Collaboration-|Project-)" }
	New-PnPTerm -Name "About Alfa Laval" -TermSet $TopNav -TermGroup $TermGroup	-Lcid 1033 -LocalCustomProperties @{ HighlightingExpression = "^https:\/\/(?:.*)\.sharepoint\.com\/sites\/(?i)(?:aboutalfalaval|organizations_Locations|StrategiesInitiatives|Sustainability|Policiesandguidelines|communicationbrand|localsitelanding(QA|UAT|)|localsite(QA|UAT|)-.+)(?:$|\/.*)" }
	New-PnPTerm -Name "IT support" -TermSet $TopNav -TermGroup $TermGroup -Lcid 1033 -LocalCustomProperties @{ HighlightingExpression = "^https:\/\/(.*)\.sharepoint\.com\/sites\/Share(UAT|QA|DEV|)/itsupport/"}
	New-PnPTerm -Name "Learning & Training" -TermSet $TopNav -TermGroup $TermGroup -Lcid 1033 -LocalCustomProperties @{ HighlightingExpression = "^https:\/\/(.*)\.sharepoint\.com\/sites\/Share(UAT|QA|DEV|)/training" }
	New-PnPTerm -Name "Old Share" -TermSet $TopNav -TermGroup $TermGroup -Lcid 1033	
} else {
	Write-Host "Top Navigation$EnvironmentPostFix term set already exists"
}

#---------------------------------------------------------------------------------------------------------------
#Create Service termSet for Alfalaval taxonomy group 

Write-Host "Checking Term groups/sets for Service Taxonomy.."

$TermGroup = Get-PnPTermGroup "Alfalaval Taxonomy" -ErrorAction SilentlyContinue
if ((Get-PnPTermSet -Identity "Service" -TermGroup $TermGroup -ErrorAction SilentlyContinue) -eq $null)
{
    Write-Host "Reading taxonomy data from XML.."

    $xmlFile = Get-Content ".\Taxonomies\Service Taxonomy.xml"
    $xml = [xml]$xmlFile

	# Reconnecting
	Disconnect-PnPOnline -ErrorAction Stop
	Start-Sleep -seconds 5
	Connect-PnPOnline -Url $Config.organizationsettings.sharePointAdminUrl -Credentials $O365Credential -ErrorAction Stop
	Start-Sleep -seconds 5

	Write-Host "Creating Service Taxonomy Term set.."
	$TermGroup = Get-PnPTermGroup "Alfalaval Taxonomy" -ErrorAction Stop

	$ServiceSet = New-PnPTermSet -Name "Service" -TermGroup $TermGroup -ErrorAction Stop -Id "de3b8b3e-a723-475b-b6ec-938d025f3088" -Lcid 1033
    
    foreach($level1 in $xml.ChildNodes.units.ServiceLevel1)  
    {
        write-host "Creating term"$level1.name
	    $parentTerm = New-PnPTerm -Name $level1.name -Id $level1.Id -TermSet $ServiceSet -TermGroup $TermGroup -Lcid 1033

        foreach($level2 in $level1.ServiceLevel2)
        {
            write-host "   Creating child term"$level2.name
            
            $childTerm = $parentTerm.CreateTerm($level2.name, 1033, $level2.Id)
            $TermGroup.Context.Load($childTerm);
            $TermGroup.Context.ExecuteQuery();
        }
    }
}
#---------------------------------------------------------------------------------------------------------------