param (
    [string]$computer
)

Import-Module ActiveDirectory

if (-not $computer) {
    $computer = Read-Host -Prompt "Input computer name:"
}

$job = Invoke-Command -ComputerName $computer -AsJob -ScriptBlock {
    $adminGroupSID = "S-1-5-32-544"
    $adminUsers = (Get-WmiObject Win32_Group -Filter "SID='$adminGroupSID'").GetRelated("Win32_UserAccount")
    $admins = $adminUsers | Select-Object -ExpandProperty Name

    $results = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True" | ForEach-Object {
        if (-not $_.Disabled) {
            $isAdmin = $admins -contains $_.Name
            [PSCustomObject]@{
                Computer      = $env:COMPUTERNAME
                Username      = $_.Name
                Administrator = if ($isAdmin) { $true } else { $false }
            }
        }
    }
    return $results
}

$results = Receive-Job -Job $job -Wait

if ($results -eq $null) {
    Write-Host "Job not returned any results"
} else {
    $results | Format-Table -AutoSize
}