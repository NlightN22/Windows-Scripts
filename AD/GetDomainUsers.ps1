param (
    [int]$days = $null
)

Import-Module ActiveDirectory

if ($days -ne $null) {
    $cutoffDate = (Get-Date).AddDays(-$days)
    $filter = {Enabled -eq $true -and LastLogonDate -lt $cutoffDate}
} else {
    $filter = {Enabled -eq $true}
}

Get-ADUser -Filter $filter -Property Name, LastLogonDate, DistinguishedName | 
    Select-Object Name, LastLogonDate, 
        @{Name="OrganizationalUnit";Expression={
            ($_.DistinguishedName -split ',') -match '^OU=' -join ','
        }} |
    Sort-Object LastLogonDate -Descending