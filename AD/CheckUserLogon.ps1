param (
    [int]$days
)

$DateThreshold = (Get-Date).Adddays(-$days)

$users = Get-ADUser -Filter * -Property LastLogonDate

foreach ($user in $users) {
    if (-not $user.LastLogonDate -or ($user.LastLogonDate -lt $DateThreshold)) {
        [PSCustomObject]@{
            UserName       = $user.SamAccountName
            LastLogonDate  = if ($user.LastLogonDate) { $user.LastLogonDate } else { "Never" }
        }
    }
}