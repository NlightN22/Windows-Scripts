param (
    [int]$days
)

# Get the current date
$currentDate = Get-Date

# Find all users in the domain
$users = Get-ADUser -Filter * -Property LastLogonTimestamp | Where-Object {
    # Users who never logged on (LastLogonTimestamp is null) or who haven't logged on in the last 'days' days
    ($_).LastLogonTimestamp -eq $null -or ($currentDate - [DateTime]::FromFileTime($_.LastLogonTimestamp)).Days -gt $days
}

# Output the list of inactive users
$users | Select-Object Name, @{Name="LastLogonDate";Expression={[DateTime]::FromFileTime($_.LastLogonTimestamp)}} | Format-Table -AutoSize
