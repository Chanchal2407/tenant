<#
	.SYNOPSIS
	 Imports the hub navigation for the SPO site provided to CSV.
	.DESCRIPTION
	 This custom function gets the Hub site navigation links for the provided SPO site.
	 It then iterates through each of the links and builds a collection to export to CSV.
	 This collection can also be integrated using pipe functions.
	.== TODO LIST == 
     1. Change Sustainability ID
     2. Change the path to CSV file
     3. Verify login credentials and password
     4. Verify site url respective domain - Dev,Qa,Uat,Prod
#>

param(
			[Parameter(Mandatory=$true)]
			[string] $navNodeID			
	)

# Set Credentials
$userName = "###USER NAME###"
$pw = "###PASSWORD###"
$securePassword = ConvertTo-SecureString -AsPlainText $pw -Force

# Get the credentials
$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName,$securePassword
$SiteUrl = "https://alfalavalonline.sharepoint.com/sites/aboutalfalaval"

$FileName = "C:\Rahul\AlfaLaval\Scripts\NavigationExport\Prod\Import-HubNavigation-PROD-16Sept20.csv"

# Connect to the site
Connect-PnPOnline -Url $SiteUrl -Credentials $credentials -ErrorAction Stop

# Remove existing nodes for sustainability
Function Remove-NavigationNode
{
    param($navNode)
    #$navNode
    if($navNode.Children.Count -gt 0)
    {
        Write-Host "Total Child nodes in Sustainability" $navNode.Children.Count
        Write-Output ""
        foreach($childNode in $navNode.Children)
        {
            #Remove child nodes
            Write-Host "Removing node: " $childNode.Id -ForegroundColor Yellow
            
            Remove-PnPNavigationNode -Identity $childNode.Id -Force
            
            Write-Host "Removed successfully" -BackgroundColor Magenta 
        }
    }    
}

$navigationNodes = Get-PnPNavigationNode -Location TopNavigationBar
#$navigationNodes
foreach($navigationNode in $navigationNodes)
{
    Write-Host $navigationNode.Id
    
    # parameter passed for Sustainability @@@@@@@@@@@@@@ TODO : change id @@@@@@@@@@@@@
    if($navigationNode.Id -eq $navNodeID){
        Write-Host "Inside Sustainabilility"
        
        $node = Get-PnPNavigationNode -Id $navigationNode.Id 
        #$node        
        
        Remove-NavigationNode $node
        break
    }
}
Write-Output ""
Write-Host "Importing CSV..." -BackgroundColor Magenta

# Import Sustainability Data from CSV 
$ImportData = Import-Csv $FileName -Encoding UTF8 -ErrorAction Stop

# Getting sustainability collection of imported csv
$navigationCol = $ImportData | Where-Object -FilterScript {$_.ParentId -eq $navNodeID} #@@@@@@@@@@@@@@ TODO : change id @@@@@@@@@@@@@

# Get the count of sub nodes
Write-Host "Count of sub nodes in CSV-Sustainability: " $navigationCol.Count

#Looping through sub node Id's
foreach($navigationObject in $navigationCol){
    Write-Output ""
    Write-Host "Sub Node - " $navigationObject.Title " Url - " $navigationObject.Url " ID - " $navigationObject.Id -BackgroundColor DarkGreen
    Write-Host "Adding Sub Node..." -ForegroundColor Yellow
    
    $Node = Add-PnPNavigationNode -Location TopNavigationBar -Title $navigationObject.Title -Url $navigationObject.Url -Parent $navigationObject.ParentId      
    
    Write-Host "Node added successfully - " $Node.Title -BackgroundColor Magenta 
    #$Node
    
    Write-Output ""
    Write-Host "Get child nodes of " $navigationObject.Title
    
    $childNodes = $ImportData |  Where-Object -FilterScript {$_.ParentId -eq $navigationObject.Id}
    
    Write-Host "Child nodes count - " $childNodes.Count    
    
    foreach($childNode in $childNodes){
        $childNode
        Write-Output ""
        Write-Host "Adding child node to sub node..." -ForegroundColor Yellow
        
        $chNode = Add-PnPNavigationNode -Location TopNavigationBar -Title $childNode.Title -Url $childNode.Url -Parent $Node.Id         
        
        Write-Host "Child Node added successfully - " $chNode.Title -BackgroundColor Magenta
        Write-Output ""
    }      
}