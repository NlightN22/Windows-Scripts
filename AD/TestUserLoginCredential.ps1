$username = Read-Host -Prompt "Input username"
$password = Read-Host -Prompt "Input password" -AsSecureString
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $password

try {
    $null = Connect-ADAccount -Credential $credential -ErrorAction Stop
    Write-Host "Success."
} catch {
    Write-Host "Failed."
}