param(
    [int]$days
)

Import-Module ActiveDirectory

# Check permissions for 'net user' by testing it on the current user
try {
    $testUserInfo = net user $env:USERNAME /domain | Out-String
} catch {
    Write-Output "Error: Access denied when running 'net user'. Please ensure you have the necessary permissions."
    exit
}

$allUsers = Get-ADUser -Filter * | Select-Object -ExpandProperty SamAccountName

# Set threshold based on days parameter if provided
if ($days) {
    $thresholdDate = (Get-Date).AddDays(-$days)
}

# Check the status and last logon of each user
foreach ($user in $allUsers) {
    try {
        # Fetch the user's last logon date from AD
        $adUser = Get-ADUser -Identity $user -Properties LastLogonDate

        if ($adUser -eq $null) {
            continue
        }

        $lastLogonDate = $adUser.LastLogonDate

        # Use 'net user /domain' to check if the account is disabled
        $userInfo = net user $user /domain | Out-String
		
        if ($LASTEXITCODE -ne 0) {
            Write-Output "Error: Unable to process user $($user) due to insufficient permissions or other error."
            exit 1
        }
        # Split the output into lines
        $lines = $userInfo -split "`n"

        # Check the sixth line
        if ($lines.Length -ge 6) {
            $statusLine = $lines[5].Trim()

            # Check for "No" in the sixth line
            if ($statusLine -match "No") {
                # If the $days parameter is provided, filter by date
                if ($days) {
                    if ($lastLogonDate -eq $null -or $lastLogonDate -lt $thresholdDate) {
                        $lastLogonDisplay = if ($lastLogonDate) { $lastLogonDate } else { "Never logged in" }
                        Write-Output "User $($user) is disabled and last logged on: $lastLogonDisplay"
                    }
                } else {
                    # If $days is not provided, display all disabled users
                    $lastLogonDisplay = if ($lastLogonDate) { $lastLogonDate } else { "Never logged in" }
                    Write-Output "User $($user) is disabled and last logged on: $lastLogonDisplay"
                }
            }
        }
    } catch {
        Write-Output "Error processing user $($user): $_"
    }
}
