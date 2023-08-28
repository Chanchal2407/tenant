cls

#region begin input
#================ Input - Start ==================

#read xml file
[xml]$config = (Get-Content ScriptConfig.xml)

$siteURL = $config.root.siteURL
$usrname = $config.root.usrname
$password = $config.root.password
$pageTemplatePath = $config.root.pageTemplatePath

#================== Input - End ==================
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

#Connect to site using PnP Online
Connect-PnPOnline -Url $siteURL -Credentials (Create-PSCredential -Username $usrname -Password $password)

#Apply page template by provisioning
Apply-PnPProvisioningTemplate -Path $pageTemplatePath -ErrorAction Stop

#disconnect
Disconnect-PnPOnline

#======================= End Main =========================