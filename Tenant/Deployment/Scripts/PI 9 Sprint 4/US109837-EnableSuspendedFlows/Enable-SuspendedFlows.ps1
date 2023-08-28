
Function Enable-SuspendedFlows(
    [Parameter(Mandatory = $True)][string] $environmentName
) {
    #Gets all flows from mentioned environment where logged in account or mentioned account has access to
    $flows = m365 flow list --environment $environmentName --output json | ConvertFrom-JSON
    
    $flows | ForEach-Object {
        Write-Output "Enabling flow... $($_.properties.displayName)"
        if($($_.properties.state) -eq 'Suspended') {
            Write-Output "Found $($_.properties.displayName) to enable..."
            m365 flow enable --name $($_.name) --environment $environmentName
        }
    }
}




#Login to Microsoft 365
m365 login
Enable-SuspendedFlows -environmentName Default-0fe89b50-008a-4818-bbdf-263cdac6a5cb
