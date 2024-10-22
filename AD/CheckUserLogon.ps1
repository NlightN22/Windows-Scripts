# Get-UsersLastLogon.ps1

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

# Iterate over each user and output their last logon date
$users | ForEach-Object {
    $lastLogon = Get-LastLogon -user $_.SamAccountName

    [PSCustomObject]@{
        Name = $_.Name
        LastLogonDate = if ($lastLogon) { [DateTime]::FromFileTime($lastLogon) } else { "Never" }
    }
} | Format-Table -AutoSize
