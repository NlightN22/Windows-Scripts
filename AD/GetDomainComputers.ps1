param (
    [int]$days = $null,
    [switch]$ip
)

Import-Module ActiveDirectory

if ($days -ne $null) {
    $cutoffDate = (Get-Date).AddDays(-$days)
    $filter = {Enabled -eq $true -and LastLogonDate -lt $cutoffDate}
} else {
    $filter = {Enabled -eq $true}
}

Get-ADComputer -Filter $filter -Property Name, LastLogonDate, DNSHostName, DistinguishedName | 
    ForEach-Object {
        $computer = $_
        $ipAddress = $null
        try {
            $ipAddress = [System.Net.Dns]::GetHostAddresses($computer.DNSHostName) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1
        } catch {
        }
		if ($ip.IsPresent) {
			$ipAddress.IPAddressToString
		} else {
			[pscustomobject]@{
				Name               = $computer.Name
				DNSHostName        = $computer.DNSHostName
				LastLogonDate      = $computer.LastLogonDate
				OrganizationalUnit = ($computer.DistinguishedName -split ',') -match '^OU=' -join ','
				IPAddress          = $ipAddress.IPAddressToString
			}
		}
    } | Sort-Object LastLogonDate -Descending