Import-Module ActiveDirectory

function Get-UserStatus {
    param (
        [string]$SamAccountName
    )

    # Use net user /domain to check if the user account is disabled
    $userInfo = net user $SamAccountName /domain
    $isDisabled = $userInfo -match "Учетная запись активна\s+No"

    # Get the user's last logon date from AD
    $adUser = Get-ADUser -Identity $SamAccountName -Properties LastLogonDate

    return [PSCustomObject]@{
        SamAccountName = $SamAccountName
        IsDisabled = $isDisabled
        LastLogonDate = $adUser.LastLogonDate
    }
}

# Get all users from the domain
$allUsers = Get-ADUser -Filter * | Select-Object SamAccountName

# Set threshold for 30 days
$thresholdDate = (Get-Date).AddDays(-30)

# Check the status and last logon of each user
foreach ($user in $allUsers) {
    $userStatus = Get-UserStatus -SamAccountName $user.SamAccountName

    if ($userStatus.IsDisabled -and ($userStatus.LastLogonDate -eq $null -or $userStatus.LastLogonDate -lt $thresholdDate)) {
        $lastLogonDisplay = if ($userStatus.LastLogonDate) { $userStatus.LastLogonDate } else { "Never logged in" }
        Write-Output "User $($userStatus.SamAccountName) is disabled and last logged on: $lastLogonDisplay"
    }
}
