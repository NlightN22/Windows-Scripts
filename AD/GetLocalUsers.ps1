$adminGroupSID = "S-1-5-32-544"
$adminUsers = (Get-WmiObject Win32_Group -Filter "SID='$adminGroupSID'").GetRelated("Win32_UserAccount")
$admins = $adminUsers | Select-Object -ExpandProperty Name

$results = Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True" | ForEach-Object {
	if (-not $_.Disabled) {
		$isAdmin = $admins -contains $_.Name
		[PSCustomObject]@{
			Computer      = $env:COMPUTERNAME
			Username      = $_.Name
			Administrator = if ($isAdmin) { "True" } else { "False" }
		}
	}
}

$results | ForEach-Object {
    "{0,-15} {1,-20} {2,-15}" -f $_.Computer, $_.Username, $_.Administrator
}