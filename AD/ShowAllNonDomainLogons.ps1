param(
  [int]$Days = 30
)

# ======================= PowerShell 2.0 friendly helpers =======================
# Build a lowercase set using Hashtable
function New-StringSet {
  $set = @{}
  $set
}
function Set-Add {
  param($set, [string]$s)
  if ($s -and $s.Trim() -ne '') {
    $set[$s.ToLower()] = $true
  }
}
function Set-Contains {
  param($set, [string]$s)
  if (-not $s) { return $false }
  return [bool]$set[$s.ToLower()]
}

# Get AD computer names via .NET DirectoryServices (works on PS 2.0, no RSAT module needed)
function Get-AdComputerNameSet {
  # Returns Hashtable as a case-insensitive set of names (short and FQDN)
  $set = New-StringSet
  try {
    $root = New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
    $nc   = $root.Properties["defaultNamingContext"][0]
    $searcher = New-Object System.DirectoryServices.DirectorySearcher([string]"LDAP://$nc")
    $searcher.PageSize = 1000
    $searcher.Filter = "(&(objectClass=computer))"
    $null = $searcher.PropertiesToLoad.Add("name")
    $null = $searcher.PropertiesToLoad.Add("dnshostname")
    $results = $searcher.FindAll()
    foreach ($r in $results) {
      if ($r.Properties["name"].Count -gt 0) {
        Set-Add $set ($r.Properties["name"][0])
      }
      if ($r.Properties["dnshostname"].Count -gt 0) {
        $fqdn = [string]$r.Properties["dnshostname"][0]
        Set-Add $set $fqdn
        if ($fqdn.Contains(".")) {
          $short = $fqdn.Split(".")[0]
          Set-Add $set $short
        }
      }
    }
  } catch {
    Write-Host "Failed to query AD computers via LDAP: $($_.Exception.Message)" -ForegroundColor Yellow
  }
  return $set
}

# Read events via wevtutil and return list of [xml] nodes
function Get-EventsXml {
  param(
    [string]$LogName,
    [int]$EventId,
    [int]$DaysBack
  )
  # wevtutil time filter uses milliseconds
  $ms = $DaysBack * 24 * 60 * 60 * 1000
  $query = "*[System[(EventID=$EventId) and TimeCreated[timediff(@SystemTime) <= $ms]]]"
  $cmd = "wevtutil qe `"$LogName`" /q:`"$query`" /f:xml /c:100000"
  $xmlText = & cmd /c $cmd
  if (-not $xmlText) { return @() }
  # Wrap into a single root if needed
  $wrapped = "<Events>$xmlText</Events>"
  try {
    $xml = [xml]$wrapped
    return $xml.Events.Event
  } catch {
    return @()
  }
}

# Safely get EventData value by Name
function Get-EventDataValue {
  param($ev, [string]$name)
  foreach ($d in $ev.EventData.Data) {
    if ($d.Name -eq $name) { return [string]$d.'#text' }
  }
  return $null
}

# Create simple PSObject for output (PS 2.0 compatible)
function New-Row {
  param($Time, $User, $ClientName, $ClientIP, $Source)
  $o = New-Object PSObject
  $o | Add-Member NoteProperty Time $Time
  $o | Add-Member NoteProperty User $User
  $o | Add-Member NoteProperty ClientName $ClientName
  $o | Add-Member NoteProperty ClientIP $ClientIP
  $o | Add-Member NoteProperty Source $Source
  return $o
}

# ============================== Main logic ====================================
$adNames = Get-AdComputerNameSet

# Security 4624 with LogonType=10 (RemoteInteractive)
$ev4624 = Get-EventsXml -LogName "Security" -EventId 4624 -DaysBack $Days
$rows4624 = @()
foreach ($e in $ev4624) {
  $lt = Get-EventDataValue $e "LogonType"
  if ($lt -ne "10") { continue }
  $wks  = Get-EventDataValue $e "WorkstationName"
  $ip   = Get-EventDataValue $e "IpAddress"
  $user = (Get-EventDataValue $e "TargetDomainName")
  $tu   = (Get-EventDataValue $e "TargetUserName")
  if ($tu) {
    if ($user) { $user = $user + "\" + $tu } else { $user = $tu }
  }
  $rows4624 += (New-Row $e.System.TimeCreated.SystemTime $user $wks $ip "4624")
}

# RDS 1149 (RemoteConnectionManager/Operational)
$rows1149 = @()
$ev1149 = Get-EventsXml -LogName "Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational" -EventId 1149 -DaysBack $Days
foreach ($e in $ev1149) {
  # 1149 payload varies; try a couple of common fields in EventData (may be empty on some builds)
  $client = $null
  $ip     = $null
  $user   = $null
  foreach ($d in $e.EventData.Data) {
    $n = [string]$d.Name
    $v = [string]$d.'#text'
    if (-not $client -and ($n -match 'Client.*Name')) { $client = $v }
    if (-not $ip -and ($n -match 'Address' -or $n -match 'IP')) { $ip = $v }
    if (-not $user -and ($n -match 'User')) { $user = $v }
  }
  # Fallback: try parse from Message text if fields were empty
  if ((-not $client -or -not $ip) -and $e.RenderingInfo) {
    $msg = [string]$e.RenderingInfo.Message
    if (-not $client -and $msg -match "Client (Machine )?Name:\s*([^\r\n]+)") { $client = $matches[2].Trim() }
    if (-not $ip -and $msg -match "(Source Network Address|IP|Address):\s*([0-9a-fA-F:\.]+)") { $ip = $matches[2].Trim() }
    if (-not $user -and $msg -match "User(Name)?:\s*([^\r\n]+)") { $user = $matches[2].Trim() }
  }
  if ($client -or $ip) {
    $rows1149 += (New-Row $e.System.TimeCreated.SystemTime $user $client $ip "1149")
  }
}

$all = @($rows4624 + $rows1149)

# Filter clients not found in AD by ClientName (case-insensitive)
$unknown = @()
foreach ($r in $all) {
  $name = $r.ClientName
  if ($name -and $name -ne '-' -and (Set-Contains $adNames $name)) {
    # known domain computer
  } else {
    $unknown += $r
  }
}

# ============== Output ==============
Write-Host "=== Non-domain RDP clients in last $Days day(s) on $env:COMPUTERNAME ===" -ForegroundColor Cyan
$unknown | Sort-Object Time | Format-Table -AutoSize Time,User,ClientName,ClientIP,Source

Write-Host "`n=== SUMMARY (grouped by ClientName or IP) ===" -ForegroundColor Cyan
# Simple grouping for PS 2.0
$groups = @{}
foreach ($r in $unknown) {
  $key = $r.ClientName
  if (-not $key) { $key = $r.ClientIP }
  if (-not $key) { $key = "<unknown>" }
  if (-not $groups.ContainsKey($key)) {
    $groups[$key] = @()
  }
  $groups[$key] += $r
}
# Print summary
$summary = @()
foreach ($k in $groups.Keys) {
  $arr = $groups[$k]
  $first = ($arr | Sort-Object Time | Select-Object -First 1).Time
  $last  = ($arr | Sort-Object Time | Select-Object -Last 1).Time
  $count = $arr.Count
  $o = New-Object PSObject
  $o | Add-Member NoteProperty Client $k
  $o | Add-Member NoteProperty First  $first
  $o | Add-Member NoteProperty Last   $last
  $o | Add-Member NoteProperty Events $count
  $summary += $o
}
$summary | Sort-Object Last -Descending | Format-Table -AutoSize Client,First,Last,Events
