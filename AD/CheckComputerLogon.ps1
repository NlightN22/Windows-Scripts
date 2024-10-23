# CheckComputerLogon.ps1 

param (
    [int]$days = 0  # The 'days' parameter is optional; default is 0, meaning all computers are displayed
)

# Get the current date
$currentDate = Get-Date

# Get all Domain Controllers
$domainControllers = Get-ADDomainController -Filter *

# Function to retrieve LastLogon from all Domain Controllers
function Get-LastLogon {
    param (
        [string]$computer
    )

    $lastLogon = $null

    foreach ($dc in $domainControllers) {
        # Retrieve the LastLogonTimestamp for the computer from each Domain Controller
        $dcLogon = (Get-ADComputer $computer -Server $dc.HostName -Property LastLogonTimestamp).LastLogonTimestamp

        if ($dcLogon -and ($null -eq $lastLogon -or $dcLogon -gt $lastLogon)) {
            $lastLogon = $dcLogon
        }
    }

    return $lastLogon
}

# Get all computers in the domain
$computers = Get-ADComputer -Filter * -Property LastLogonTimestamp

# Iterate over each computer and output based on 'days' condition
$computers | ForEach-Object {
    $lastLogon = Get-LastLogon -computer $_.SamAccountName

    # If 'days' is not specified (equal to 0), display all computers.
    # If 'days' is specified, display only those that have not logged in for more than 'days' days.
    if ($days -eq 0 -or ($lastLogon -and ($currentDate - [DateTime]::FromFileTime($lastLogon)).Days -gt $days)) {
        [PSCustomObject]@{
            Name = $_.Name
            LastLogonDate = if ($lastLogon) { [DateTime]::FromFileTime($lastLogon) } else { "Never" }
        }
    }
} | Format-Table -AutoSize
