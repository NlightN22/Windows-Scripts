param(
    [string]$User,
    [string[]]$Processes,
    [switch]$Stop
)

$procNames = if ($Processes) { $Processes } else { $null }

$procs = Get-CimInstance Win32_Process

if ($User) {
    $procs = $procs | Where-Object {
        (Invoke-CimMethod -InputObject $_ -MethodName GetOwner).User -eq $User
    }
}

if ($procNames) {
    $filtered = @()
    foreach ($p in $procs) {
        $name = $p.Name
        if ($procNames -contains $name) {
            $filtered += $p
        }
    }
    $procs = $filtered
}

if ($Stop) {
    foreach ($p in $procs) {
        $ownerInfo = Invoke-CimMethod -InputObject $p -MethodName GetOwner
        $userName = "$($ownerInfo.Domain)\$($ownerInfo.User)"
        $processName = $p.Name
        $processId = $p.ProcessId
        $memoryMB = [math]::Round($p.WorkingSetSize / 1MB, 2)
        Write-Host "Stopping process:"
        Write-Host "  Name          : $processName"
        Write-Host "  PID           : $processId"
        Write-Host "  User          : $userName"
        Write-Host "  Memory (MB)   : $memoryMB"
        Write-Host "-----------------------------------"
        Stop-Process -Id $processId -Force
    }
} else {
    $procs | ForEach-Object {
        $owner = Invoke-CimMethod -InputObject $_ -MethodName GetOwner
        [PSCustomObject]@{
            User      = "$($owner.Domain)\$($owner.User)"
            Name      = $_.Name
            ProcessId = $_.ProcessId
        }
    }
}
