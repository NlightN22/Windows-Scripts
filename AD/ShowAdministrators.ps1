$adminGroupSID = "S-1-5-32-544"

(Get-WmiObject Win32_Group -Filter "SID='$adminGroupSID'").GetRelated("Win32_UserAccount")