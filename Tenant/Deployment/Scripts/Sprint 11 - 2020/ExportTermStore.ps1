#Load SharePoint CSOM Assemblies
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"


$TermGroup = Read-Host "Please enter Term Group name"

$TermSets =  Read-Host "Please enter Term set Name/Names with comma separated"
   
#Variables for Processing
$AdminURL = "https://alfalavalonline-admin.sharepoint.com/"
$TermGroupName = $TermGroup
$TermSetNames =   $TermSets #"Categories"
$CSVFile="C:\Temp\TermSet.csv"
 

 foreach($TermSetName in $TermSetNames.Split(','))
 {
#Custom Function get child terms of a given term
Function Get-Terms([Microsoft.SharePoint.Client.Taxonomy.Term] $Term,[String]$ParentTerm,[int] $Level)
{
  $ChildTerms = $Term.Terms
  $Ctx.Load($ChildTerms)
  $Ctx.ExecuteQuery()
  if($ParentTerm)
  {
    $ParentTerm = $ParentTerm + "," + $Term.Name
  }
  else
  {
    $ParentTerm = $Term.Name
  }
 
  Foreach ($SubTerm in $ChildTerms)
  {
     $Level = $Level + 1
     #Terms may have upto 7 levels
     $NumofCommas =  7 - $Level
     $commas =""
      
     #Append Commas
     For ($j=0; $j -lt $NumofCommas; $j++) 
     {
        $Commas = $Commas + ","
     }
     
    #Append the Output to CSV File
    "," + "," + "," + $Term.IsAvailableForTagging + ",""$($Term.Description)""," + $ParentTerm + "," + $SubTerm.Name + $Commas >> $CSVFile
     
    #Call the function recursively
    Get-Terms -Term $SubTerm -ParentTerm $ParentTerm -Level $Level
  }
}
Try {
    #Get Credentials to connect
    $Cred = Get-Credential
    $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
 
    #Setup the context
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($AdminURL)
    $Ctx.Credentials = $Credentials
 
    #Get the term store
    $TaxonomySession=[Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($Ctx)
    $TermStore =$TaxonomySession.GetDefaultSiteCollectionTermStore()
    $Ctx.Load($TaxonomySession)
    $Ctx.Load($TermStore)
    $Ctx.ExecuteQuery()
 
    #Write Termset CSV Header (As in the standard format)
    "Term Set Name,Term Set Description,LCID,Available for Tagging,Term Description,Level 1 Term,Level 2 Term,Level 3 Term,Level 4 Term,Level 5 Term,Level 6 Term,Level 7 Term" > $CSVFile
 
    #Get the Term Group
    $TermGroup=$TermStore.Groups.GetByName($TermGroupName)
 
    #Get the term set
    $TermSet = $TermGroup.TermSets.GetByName($TermSetName)
    $Ctx.Load($Termset)
    $Ctx.ExecuteQuery()
 
    #Get all tersm from the term set
    $Terms = $TermSet.Terms
    $Ctx.Load($Terms)
    $Ctx.ExecuteQuery()
 
    #Write 2nd line as Termset properties(As per standard format)
    $TermSet.Name + ",""$($TermSet.Description)""," + $TermStore.DefaultLanguage + "," + $TermSet.IsAvailableForTagging + ",""$($Terms[0].Description)""," + $Terms[0].Name + "," + "," + "," + "," + "," + "," >> $CSVFile
     
    #Process each Term in the termset
    Foreach($Term in $Terms) 
    {
        write-host $Term.Name
        Get-Terms $Term -Level 1 -ParentTerm ""
    }    
    Write-host "Term Set Data Exported Successfully!" -ForegroundColor Green
}
Catch {
    write-host -f Red "Error Exporting Term Set!" $_.Exception.Message
}

}