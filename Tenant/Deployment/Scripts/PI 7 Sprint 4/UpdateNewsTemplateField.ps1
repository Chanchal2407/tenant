cls
#region begin input
############### Input - Start ###############

#read xml file
[xml]$config = (Get-Content ScriptConfig.xml)

$tenantURL = $config.root.tenantURL
$siteURL = ($config.root.tenantURL + $config.root.siteURL)
$listName = $config.root.listName
$corporateNewsTemplate = $config.root.corporateNewsTemplate
$newsTemplate = $config.root.newsTemplate
$usrname = $config.root.usrname
$password = $config.root.password
$Files = $config.root.ReportOutput

$TemplateType=""
$corporateNewsCTId = ""
$newsCTId = ""

#Object array.
$SiteData = @()

############### Input - End ###############
#endregion

#Creates a PS credential object.
Function Create-PSCredential
{
    [cmdletbinding()]	
		
    Param
    (
        [Parameter(Mandatory=$true, HelpMessage="Please provide a valid username, example 'Domain\Username'.")]$Username,
        [Parameter(Mandatory=$true, HelpMessage="Please provide a valid password, example 'MyPassw0rd!'.")]$Password
    )
 
    #Convert the password to a secure string.
    $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
 
    #Convert $Username and $SecurePassword to a credential object.
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$SecurePassword
 
    #Return the credential object.
    Return $Credential
}
 
#======================= Main ============================
#Connect to PnP Online
Connect-PnPOnline -Url $siteURL -Credentials (Create-PSCredential -Username $usrname -Password $password)
  
#Get All Items from the List in batches
$ListItems = Get-PnPListItem -List $listName -PageSize 1000
Write-host "Total Number of Items Found:"$ListItems.count
 
#Filter List Items
$FilteredItems  = $ListItems | Where {$_["FileLeafRef"] -eq $corporateNewsTemplate -or $_["FileLeafRef"] -eq $newsTemplate}

$FilteredItems | ForEach-Object { 
    If($_["FileLeafRef"] -eq $newsTemplate) {
        $newsCTId = $_["ContentTypeId"]
        Write-Host "Type - " $_["FileLeafRef"] 
        Write-Host "CTTypeID - " $_["ContentTypeId"]
    }else{
            $corporateNewsCTId = $_["ContentTypeId"]
            Write-Host "Type - " $_["FileLeafRef"] 
            Write-Host "CTTypeID - " $_["ContentTypeId"]
         }
 }

#If there is any list items.
If($ListItems)
{
    #Foreach list item.
    Foreach($ListItem in $ListItems)
    {

        #If the page is a .ASPX page.
        If($ListItem.FieldValues.File_x0020_Type -eq "aspx")         
        {
            If(($ListItem.FieldValues.ContentTypeId -like $corporateNewsCTId) -or ($ListItem.FieldValues.ContentTypeId -like $newsCTId))
            {
                If(($ListItem.FieldValues.FileLeafRef -ne $corporateNewsTemplate) -and ($ListItem.FieldValues.FileLeafRef -ne $newsTemplate))
                {                    
                    #Update List Item - General 
                    Set-PnPListItem -List $listName -Identity $ListItem -Values @{"ShareNewsTemplateType"= "General"} -SystemUpdate -ErrorAction SilentlyContinue
                    
                    If($ListItem.FieldValues.ContentTypeId.StringValue -eq $newsCTId.StringValue){
                        $TemplateType = "News"
                    }else{
                        $TemplateType = "Corporate News"
                    }

                    Write-Host $TemplateType " - " ($tenantURL + $ListItem.FieldValues.FileRef)                                       
                    Write-Host ""

                    $row = New-Object PSObject                    
                    $row | Add-Member -MemberType NoteProperty -Name "PageURL" -Value ($tenantURL + $ListItem.FieldValues.FileRef)
                    $row | Add-Member -MemberType NoteProperty -Name "TemplateType" -Value $TemplateType                    
                    $row | Add-Member -MemberType NoteProperty -Name "ContentTypeId" -Value $ListItem.FieldValues.ContentTypeId
                    $row | Add-Member -MemberType NoteProperty -Name "CheckedOutByUser" -Value $ListItem.FieldValues.CheckoutUser.Email                    
                    #$row | Add-Member -MemberType NoteProperty -Name "Error" -Value $error
                    $SiteData += $row
                                 
                }
            }                                                 
        }
    }
}

$SiteData #Print Data

$SiteData | Export-Csv $Files -NoTypeInformation

Disconnect-PnPOnline
