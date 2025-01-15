param (
    [string]$CIDR = "192.168.0.0/24" # Default subnet in CIDR format
)

# Function to calculate all IP addresses from the CIDR
function Get-IPRangeFromCIDR {
    param (
        [string]$CIDR
    )

    # Validate and split the CIDR into base IP and prefix
    if ($CIDR -match '^(\d{1,3}(\.\d{1,3}){3})\/(\d{1,2})$') {
        $baseIP = $matches[1]
        $prefix = [int]$matches[3]

        # Ensure prefix is valid
        if ($prefix -lt 0 -or $prefix -gt 32) {
            throw "Invalid CIDR prefix: $prefix. It must be between 0 and 32."
        }
    } else {
        throw "Invalid CIDR format. Use format like '192.168.0.0/24'."
    }

    # Convert base IP to UInt32
    $ipBytes = ([IPAddress]$baseIP).GetAddressBytes()
    [Array]::Reverse($ipBytes) # Convert to little-endian for calculations
    $ipUInt32 = [BitConverter]::ToUInt32($ipBytes, 0)

    # Calculate network range using UInt32
    $netmask = -bnot ([uint32]([math]::Pow(2, 32 - $prefix) - 1))
    $networkStart = $ipUInt32 -band $netmask
    $networkEnd = $networkStart + ([uint32]([math]::Pow(2, 32 - $prefix) - 1))

    # Generate all IP addresses in the range
    $ipList = @()
    for ($currentIP = $networkStart; $currentIP -le $networkEnd; $currentIP++) {
        $addressBytes = [BitConverter]::GetBytes([uint32]$currentIP)
        [Array]::Reverse($addressBytes) # Convert back to big-endian
        $ipList += [IPAddress]::new($addressBytes)
    }
    return $ipList
}

# Get the IP range from the CIDR
try {
    $ipList = Get-IPRangeFromCIDR -CIDR $CIDR
} catch {
    Write-Error $_.Exception.Message
    exit 1
}

# Scan each IP address for availability
foreach ($ip in $ipList) {
    if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
        Write-Output "$ip is reachable"
    }
}
