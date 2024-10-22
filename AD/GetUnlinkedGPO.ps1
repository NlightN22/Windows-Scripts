# Import GroupPolicy module
Import-Module GroupPolicy

# Get all GPOs
$allGPOs = Get-GPO -All

# Retrieve GPO Reports in XML format and check for <LinksTo>
$unlinkedGPOs = @()

foreach ($gpo in $allGPOs) {
    # Get the XML report for the GPO
    $gpoReport = Get-GPOReport -Guid $gpo.Id.Guid -ReportType XML

    # Parse the XML
    $xml = [xml]$gpoReport

    # Add namespace manager
    $namespaceManager = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $namespaceManager.AddNamespace("ns", "http://www.microsoft.com/GroupPolicy/Settings")

    # Use XPath to check for the <LinksTo> element with the namespace
    $linksTo = $xml.SelectNodes("//ns:LinksTo", $namespaceManager)
	
    # If <LinksTo> exists and has at least one entry, we consider this GPO as linked
    if ($linksTo.Count -eq 0) {
        $unlinkedGPOs += $gpo
    }
}

# Output unlinked GPOs
$unlinkedGPOs | Select-Object DisplayName, Id