param (
    [string]$username
)

Import-Module ActiveDirectory

if (-not $username) {
    $username = Read-Host -Prompt "Enter username"
}

$user = Get-ADUser -Identity $username -Properties *

# Display all user properties
$user | Format-List *


if ($user."msDS-User-Account-Control-Computed" -band 2) {
    Write-Host "User is disabled"
} else {
    Write-Host "User is active"
}

Write-Host "User account creation date: $($user.whenCreated)"


$auditLog = Get-WinEvent -LogName "Security" | Where-Object { $_.Id -eq 4720 -and $_.Properties[0].Value -eq $user.DistinguishedName } | Select-Object -First 1
if ($auditLog) {
    $creator = $auditLog.Properties[1].Value
    Write-Host "Account created by: $creator"
} else {
    Write-Host "No account creation audit log entry found for this user."
}