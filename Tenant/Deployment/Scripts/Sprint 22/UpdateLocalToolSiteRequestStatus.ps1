cls

#$SiteUrl = "https://alfalavalonline.sharepoint.com/sites/localsitelandinguat" #local UAT
#$SiteUrl = "https://alfalavalonline.sharepoint.com/sites/localsitelandingQA" #local QA
#$SiteUrl = "https://alfalavalonline.sharepoint.com/sites/localsitelanding" #local PRD


#$SiteUrl = "https://alfalavalonline.sharepoint.com/sites/toolsitelandinguat" #Tool UAT
$SiteUrl = "https://alfalavalonline.sharepoint.com/sites/toolsitelandingqa" #Tool QA
#$SiteUrl = "https://alfalavalonline.sharepoint.com/sites/toolsitelanding" #Tool PRD

#$SiteUrl = "https://atvarssp.sharepoint.com/sites/toolsitelanding" # DEV

$User = "xx@alfalaval.com" # Alfalaval Tenant
$PassWord = "xx" # Alfalaval Tenant


#$User = "atvars@atvarssp.onmicrosoft.com" # DEV Tenant
#$PassWord = "xx" # DEV Tenant


#$listName = "All Local sites" #local sites
#$siteStatusColumn = "shareSiteStatus" # local sites


$listName = "All Tool sites" #Tool Sites
$siteStatusColumn = "SiteStatus"   #Tool Sites

$PWord = ConvertTo-SecureString -String $PassWord -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
echo "Connecting to '$SiteUrl'";

Connect-PnPOnline $SiteUrl -Credentials $Credential

echo "Get items with status 'Published' from list '$listName'";

$list = Get-PnPList -Identity $listName


 $Query = "
                <View>
                   <Query>
                       <Where>
                           <Eq>
                              <FieldRef Name='$siteStatusColumn' />
                               <Value Type='Text'>Published</Value>
                           </Eq>
                              </Where>
                           </Query>
                         <ViewFields>
                             <FieldRef Name='ID' />
                         </ViewFields>
                </View>
                "

$Items = Get-PnPListItem -List $list -Query $Query

echo "Start to set status Published as Avialable";

foreach($item in $items)
{

  $res = Set-PnPListItem -List $list -Identity $item.ID -Values @{$siteStatusColumn = "Available"};
  echo "Item with ID:  $($item.ID) updated"

}

echo 'Done'