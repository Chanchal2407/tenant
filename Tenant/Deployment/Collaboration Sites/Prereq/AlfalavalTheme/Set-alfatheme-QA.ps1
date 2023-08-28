<#
Pre-Req : Run it in SharePoint online Management shell
          SharePoint online powershell module must be loaded
#>

function HashToDictionary {
    Param ([Hashtable]$ht)
    $dictionary = New-Object "System.Collections.Generic.Dictionary``2[System.String,System.String]"
    foreach ($entry in $ht.GetEnumerator()) {
      $dictionary.Add($entry.Name, $entry.Value)
    }
    return $dictionary
 }
 
 $themepallette = HashToDictionary(
@{
    "bodyText"= "#3D3935";
    "neutralPrimaryAlt"= "#373636";
    "themeLighterAlt"= "#f1f0fc";
    "black"= "#222121";
    "themeTertiary"= "#8685e2";
    "primaryBackground"= "#F5F3F2";
    "neutralQuaternaryAlt"= "#d6d6d6";
    "themePrimary"= "#11387F";
    "neutralSecondary"= "#514f4f";
    "themeLighter"= "#e2e2f8";
    "themeDark"= "#151454";
    "neutralPrimary"= "#3D3935";
    "neutralLighterAlt"= "#f3f3f3";
    "neutralLighter"= "#efefef";
    "neutralDark"= "#2b2a2a";
    "neutralQuaternary"= "#cccccc";
    "neutralLight"= "#e5e5e5";
    "primaryText"= "#3D3935";
    "themeDarker"= "#111042";
    "neutralTertiaryAlt"= "#c4c4c4";
    "themeDarkAlt"= "#1b1a6c";
    "bodyBackground"= "#F5F3F2";
    "themeSecondary"= "#262495";
    "white"= "#fbfbfb";
    "disabledBackground"= "#efefef";
    "neutralTertiary"= "#d9d8d8";
    "themeLight"= "#c5c5f1";
    "disabledText"= "#c4c4c4";
} 
)

$siteUrl = Read-Host "Enter admin tenant url (Ex: https://xxx-admin.sharepoint.com)"
Connect-SPOService -Url $siteUrl
Add-SPOTheme -Name "Alfalaval theme-QA" -Palette $themepallette -IsInverted $false -Overwrite
Disconnect-SPOService