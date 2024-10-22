# Get-UserLastLogon.ps1

param (
    [int]$days = 0  # The 'days' parameter is optional; default is 0, meaning all users are displayed
)

# Get the current date
$currentDate = Get-Date

# Get all Domain Controllers
$domainControllers = Get-ADDomainController -Filter *

# Function to retrieve LastLogon from all Domain Controllers
function Get-LastLogon {
    param (
        [string]$user
    )

    $lastLogon = $null

    foreach ($dc in $domainControllers) {
        $dcLogon = (Get-ADUser $user -Server $dc.HostName -Property LastLogon).LastLogon

        if ($dcLogon -and ($null -eq $lastLogon -or $dcLogon -gt $lastLogon)) {
            $lastLogon = $dcLogon
        }
    }

    return $lastLogon
}

# Get all users in the domain
$users = Get-ADUser -Filter * -Property LastLogon

# Iterate over each user and output based on 'days' condition
$users | ForEach-Object {
    $lastLogon = Get-LastLogon -user $_.SamAccountName

    # If 'days' is not specified (equal to 0), display all users.
    # If 'days' is specified, display only those who have not logged in for more than 'days' days.
    if ($days -eq 0 -or ($lastLogon -and ($currentDate - [DateTime]::FromFileTime($lastLogon)).Days -gt $days)) {
        [PSCustomObject]@{
            Name = $_.Name
            LastLogonDate = if ($lastLogon) { [DateTime]::FromFileTime($lastLogon) } else { "Never" }
        }
    }
} | Format-Table -AutoSize
