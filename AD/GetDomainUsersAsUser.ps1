# Import Active Directory module if available
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

# Check if the Active Directory module is loaded
if (Get-Module -Name ActiveDirectory) {
    # Retrieve the domain name
    $domainName = (Get-ADDomain).DNSRoot

    # Get the list of all users in the domain
    $users = Get-ADUser -Filter * -Server $domainName -Properties DisplayName | Select-Object Name, SamAccountName, DisplayName

    # Output the results
    $users | Format-Table -AutoSize
} else {
    Write-Error "Active Directory module is not available. Please install the RSAT tools or ensure the module is loaded."
}
