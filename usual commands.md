# snap-ins
- Device Manager - `devmgmt.msc`
- Disk Management - `diskmgmt.msc`
- Event Viewer - `eventvwr.msc`
- Local Group Policy Editor - `gpedit.msc`
- Performance Monitor - `perfmon.msc`
- Services - `services.msc`
- Task Scheduler - `taskschd.msc`
- Windows Firewall with Advanced Security - `wf.msc`
- Component Services - `comexp.msc`
- System - `sysdm.cpl`
- Programs and components - `appwiz.cpl`
- Credential Manager - `control /name Microsoft.CredentialManager`
- Network connections - `ncpa.cpl`
- System Properties - `SystemPropertiesAdvanced`

# Network
lan passwords: 
``` batch 
rundll32.exe keymgr.dll, KRShowKeyMgr
```
Statistic NetBIOS throught TCP/IP
``` batch
nbtstat -A x.x.x.x
```
Show opened ports:
``` powershell
netstat -abn | Select-String "LISTEN"
```
Show opened ports and processes:
``` powershell
netstat -aon | Where-Object { $_ -match "LISTEN" } | ForEach-Object {
    $fields = ($_ -split '\s+')
    $localAddress = $fields[2]
    $state = $fields[4]
    $procId = $fields[5]
    $process = Get-Process -Id $procId -ErrorAction SilentlyContinue
    $processName = if ($process) { $process.ProcessName } else { "Unknown" }

    "Local Address: {0}, State: {1}, PID: {2}, Process: {3}" -f $localAddress, $state, $procId, $processName
}


```
``` batch 
netstat -abn | find "LISTEN"
```
Add rule to firewall
``` powershell
New-NetFirewallRule -DisplayName "Allow ICMP" -Direction Inbound -Protocol ICMPv4 -Action Allow -Enabled True
```
# System
Autostart folder windows 11:
``` batch
shell:startup
```
## Show last success logon:
``` powershell
$logonEventId = 4624
$logonEvents = Get-WinEvent -FilterHashtable @{LogName="Security"; Id=$logonEventId} -MaxEvents 10

$logonEvents | ForEach-Object {
    $event = [xml]$_.ToXml()
    [pscustomobject]@{
        TimeCreated = $_.TimeCreated
        AccountName = $event.Event.EventData.Data[5].'#text'
        AccountDomain = $event.Event.EventData.Data[6].'#text'
        LogonType = $event.Event.EventData.Data[8].'#text'
        SourceNetworkAddress = $event.Event.EventData.Data[18].'#text'
    }
} | Format-Table -AutoSize

```
## benchmark
``` batch
diskspd -c1G -w100 -b128K -o1 -W0 -d60 -Sh testfile.dat > pve-01.fileio.test
winsat disk -seq -read -drive C
winsat disk -seq -write -drive C
winsat disk -seq -write -drive E
```
# Task manager
Start task from cli:
``` batch
schtasks /Run /TN "StartExchange"
```

# SMB
## attach share to local PC
``` batch
net use Z: \\servername\vm-backup /user:<USERNAME> <PASSWORD>
```
## delete share from local PC
``` batch
net use z: /delete
```
# AD
Show replication status
``` batch
repadmin /showrepl
```
If replications failed.
- Stop KDC on target broken controller
``` batch
net stop KDC
```
- Run replication from Active Directory Sites and Services or by command
``` batch
Repadmin /replicate ContosoDC2.contoso.com ContosoDC1.contoso.com "DC=contoso,DC=com"
```
- Check replication:
``` batch
repadmin /replsummary
repadmin /showrepl
```
- Current user policies:
``` batch
gpresult /R
```
- Group and PC policies:
``` batch
gpresult /H GPReport.html
```
- Update policies:
``` batch
gpupdate /force
```
# GPO
- Show all GPO:
``` powershell
Get-GPO -All
```
- Show GPO info:
``` powershell
Get-GPO -Name "GPO_NAME"
```
``` powershell
Get-GPO -Guid "GUID_GPO"
```
- Show GPO report:
``` powershell
Get-GPOReport -Name "GPO Name" -ReportType XML -Path "GPOReport.xml" ; cat ./GPOReport.xml
```
- Check information about GPO for current user and PC:
``` batch
gpresult /r
```
- Check information about GPO for PC:
``` batch
gpresult /scope computer /r
```
# PowerShell
## Install git:
``` powershell
winget install --id Git.Git -e --source winget
```
## Allow|Enable scripts
``` powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```
## WinRM
Enable Remoting on remote machine:
``` powershell
Enable-PSRemoting -Force
```
Https:
``` powershell
New-SelfSignedCertificate -DnsName "10.10.10.10" -CertStoreLocation Cert:\LocalMachine\My
winrm quickconfig -transport:https
dir Cert:\LocalMachine\My # copy Thumbprint e.g. 5440349A35B2E4C47B3B6D0FEA23760083378504
winrm create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="10.10.10.10"; CertificateThumbprint="5440349A35B2E4C47B3B6D0FEA23760083378504"} # or
New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{Address="*"; Transport="HTTPS"} -ValueSet @{Hostname="10.10.10.10"; CertificateThumbprint="5440349A35B2E4C47B3B6D0FEA23760083378504"}
Export-Certificate -Cert (Get-ChildItem -Path Cert:\LocalMachine\My\5440349A35B2E4C47B3B6D0FEA23760083378504) -FilePath C:\certificate.cer # copy to client and add
```
Выполните команду на удаленной машине:
``` powershell
Invoke-Command -ComputerName 10.10.10.10 -ScriptBlock { Get-Service } -Credential (Get-Credential)
```
Подключиться:
``` powershell
Enter-PSSession -ComputerName 10.10.10.10 -Credential (Get-Credential)
```
Подключиться:
``` powershell
Enter-PSSession -ComputerName 10.10.10.10 -UseSSL -Credential (Get-Credential)
```
Add to trusted host:
``` powershell
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "10.10.10.10"
```
Отключиться:
``` powershell
Exit-PSSession
```
# Copy
robocopy /R:5 /W:5 /Z /V "M:\SQL" "E:\SQL\work" taskmgr.mdf taskmgr_log.LDF
