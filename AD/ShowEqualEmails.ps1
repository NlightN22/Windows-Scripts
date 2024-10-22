Import-Module ActiveDirectory

$users = Get-ADUser -Filter * -Property EmailAddress | Where-Object {$_.EmailAddress -ne $null}

$duplicateEmails = $users | Group-Object -Property EmailAddress | Where-Object {$_.Count -gt 1}

foreach ($group in $duplicateEmails) {
    Write-Output "Email: $($group.Name)"
    foreach ($user in $group.Group) {
        $ou = ($user.DistinguishedName -split ',')[1..($user.DistinguishedName.Length)] -join ',' -replace '^OU=', ''
        Write-Output "User: $($user.SamAccountName)"
        Write-Output "Created: $($user.WhenCreated)"
        Write-Output "OU: $ou"
        Write-Output "------"
    }
    Write-Output "------"
}