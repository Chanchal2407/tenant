# Steps to Create .pnp file

# Run below command to create .pnp Office Open XML file

$kit = Read-PnPTenantTemplate -Path "{FilePeople.xml path}"
Save-PnPTenantTemplate -Template $kit -Out FindPeople.pnp