param(
    [Parameter(Mandatory)]
    [string]$Text,                         

    [string]$Title = 'Information',         

    [ValidateSet('None','Error','Question','Warning','Information')]
    [string]$Icon = 'Information'        
)

switch ($Icon) {
    'None'        { $iconFlag = 0x00 }
    'Error'       { $iconFlag = 0x10 }
    'Question'    { $iconFlag = 0x20 }
    'Warning'     { $iconFlag = 0x30 }
    'Information' { $iconFlag = 0x40 }
}

$wshell = New-Object -ComObject WScript.Shell

$wshell.Popup($Text, 0, $Title, $iconFlag)