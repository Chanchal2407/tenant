function Get-SPOHubSiteNavigation{
	<#
	.SYNOPSIS
	 Exports the hub navigation for the SPO site provided to CSV.
	.DESCRIPTION
	 This custom function gets the Hub site navigation links for the provided SPO site.
	 It then iterates through each of the links and builds a collection to export to CSV.
	 This collection can also be integrated using pipe functions.
	.PARAMETER Identity 
	 Specifies the Url for the SPO site where the navigation should be exported from.
	.PARAMETER Export 
	 Specifies whether the navigation should be exported or not. The export is saved to the current directory.
	.EXAMPLE
	 PS C:\>Get-SPOHubNavigation -Identity https://[tenant].sharepoint.com/sites/[site] -Export:$true
    .Update credentials and output file name below.
	#>
	param(
			[Parameter(Mandatory=$true)]
			[string] $Identity,
			[Parameter(Mandatory=$true)]
			[boolean] $Export
	)
	begin{
			$exportNavCol = @()
			# This counter is used in order to maintain the order of the navigation. 
			# The navigation is returned in the order it appears.
			$counter = 1
			Write-Debug "$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")) Get-SPOHubNavigation function started."
	}
	process{
			# Connect to the hub site
			$userName = "rahul.cheke_a@alfalaval.com"
			$pw = "Rach_A@123"
			$securePassword = ConvertTo-SecureString -AsPlainText $pw -Force
			# Get the credentials
			$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $userName,$securePassword
			$connection = Connect-PnPOnline -Url $identity -Credentials $credentials
			$site = Get-PnPSite

			Write-Debug "$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")) Exporting navigation from $($site.Url)..."

			# Get the master navigation
			$navigationNodes = Get-PnPNavigationNode -Location TopNavigationBar -Connection $connection
			
			# Iterate through the navigation and capture all the nodes on all 3 levels
			foreach($navigationNode in $navigationNodes){
					$parentNode = Get-PnPNavigationNode -id $navigationNode.Id
					$navInfo = New-Object PSObject -property @{
							Level = "Level 1"
							Id = $navigationNode.Id
							Title = $navigationNode.Title
							Url = $navigationNode.Url
							ParentId = "0"
							ParentTitle = ""
							Visible = $navigationNode.IsVisible
							Order = $counter
					}
					# Add the navInfo collection to the collection we're going to export.
					$exportNavCol += $navInfo
					$counter++

					# Get the second level navigation
					$navigation = Get-PnPNavigationNode -Id $navigationNode.Id
					$children = $navigation.Children

					# If children exist proceed
					if($children){
							foreach($child in $children){
									# Get the node and further information about the link
									$childNode = Get-PnPNavigationNode -Id $child.Id
									$navInfo = New-Object PSObject -property @{
											Level = "Level 2"
											Id = $childNode.Id
											Title = $childNode.Title
											Url = $childNode.Url
											ParentId = $parentNode.Id
											ParentTitle = $parentNode.Title
											Visible = $childNode.IsVisible
											Order = $counter
									}

									# Add the navInfo collection to the collection we're going to export.
									$exportNavCol += $navInfo
									$counter++

									# Get the third level navigation
									$subChildren = $childNode.Children

									# if children exist proceed
									if($subChildren) {
											foreach($subChild in $subChildren) {
													# Get the node and further information about the link
													$subChildNode = Get-PnPNavigationNode -Id $subChild.Id
													$navInfo = New-Object PSObject -property @{
															Level = "Level 3"
															Id = $subChildNode.Id
															Title = $subChildNode.Title
															Url = $subChildNode.Url
															ParentId = $childNode.Id
															ParentTitle = $childNode.Title
															Visible = $childNode.IsVisible
															Order = $counter
													}
													# Add the navInfo collection to the collection we're going to export.
													$exportNavCol += $navInfo
													$counter++
											}
									}       
							}
					}
			}
			Disconnect-PnPOnline -Connection $connection
	}
	end{                
			# Rebuild collection with sort
			$returnCol = @()
			$returnCol = $exportNavCol | Sort-Object Order

			# Export the navigation to a CSV file if the switch is enabled
			if($Export -eq $true){
					#$exportFile = ".\Output-HubNavigation-$((Get-Date).ToString("yyyymmddhhss")).csv"
					$exportFile = ".\Output-HubNavigation-PROD-12June20.csv"
					Write-Debug "$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")) Navigation exported to '$($exportFile)'."
					$returnCol | Export-Csv $exportFile -NoTypeInformation -Append:$false -Force:$true
			}

			Write-Debug "$((Get-Date).ToString("yyyy-MM-dd HH:mm:ss")) Get-SPOHubNavigation finished."
			
			return $returnCol
	}
}

#Function Calls

#Call Get navigation function to export navigation in CSV format
Get-SPOHubSiteNavigation

#Call Create navigation function to add navigatio in site
